shared_context 'common headers' do
  let(:common_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
end

shared_context 'without authentication' do
  include_context 'common headers'
  let(:headers) { common_headers }
end

shared_context 'with authentication' do
  include_context 'common headers'
  let(:user_auth) {
    FactoryBot.create(:user_authentication_service, :populated)
  }
  let(:current_user) { user_auth.user }
  let(:api_token) {
    ApiToken.new(user: current_user, user_authentication_service: user_auth).api_token
  }
  let(:headers) {{'Authorization' => api_token}.merge(common_headers)}
end

shared_context 'with software_agent authentication' do
  include_context 'common headers'
  let(:current_user) {
    FactoryBot.create(:user, :with_key)
  }
  let (:software_agent) {
    FactoryBot.create(:software_agent, :with_key, creator: current_user)
  }
  let(:api_token) {
    ApiToken.new(user: current_user, software_agent: software_agent).api_token
  }
  let(:headers) {{'Authorization' => api_token}.merge(common_headers)}
  let(:audit_should_include) {{
    user: current_user,
    software_agent: software_agent
  }}
end

shared_context 'request parameters' do |url_sym: :url, payload_sym: :payload, headers_sym: :headers|
  let(:request_url) { send(url_sym) }
  let(:request_payload) { send(payload_sym) }
  let(:request_headers) { send(headers_sym) }
end

shared_examples 'a GET request' do |url_sym: :url, payload_sym: :payload, headers_sym: :headers, response_status: 200|
  include_context 'request parameters', url_sym: url_sym, payload_sym: payload_sym, headers_sym: headers_sym
  let(:expected_response_status) { response_status }
  let(:called_action) { "GET" }
  subject { get(request_url, params: request_payload, headers: request_headers) }
end

shared_examples 'a POST request' do |url_sym: :url, payload_sym: :payload, headers_sym: :headers, response_status: 201|
  include_context 'request parameters', url_sym: url_sym, payload_sym: payload_sym, headers_sym: headers_sym
  let(:expected_response_status) { response_status }
  let(:called_action) { "POST" }
  subject { post(request_url, params: request_payload.to_json, headers: request_headers) }
end

shared_examples 'a PUT request' do |url_sym: :url, payload_sym: :payload, headers_sym: :headers, response_status: 201|
  include_context 'request parameters', url_sym: url_sym, payload_sym: payload_sym, headers_sym: headers_sym
  let(:expected_response_status) { response_status }
  let(:called_action) { "PUT" }
  subject { put(request_url, params: request_payload.to_json, headers: request_headers) }
end

shared_examples 'a listable resource' do |persisted_resource: true|
  let(:expected_resources) { resource_class.all }
  let(:serializable_resource) { resource }
  let(:expected_list_length) { expected_resources.count }
  let(:unexpected_resources) { [] }
  let(:expected_response_status) { 200 }

  if persisted_resource
    before do
      expect(resource).to be_persisted
    end
  end

  it 'should return a list that includes a serialized resource' do
    is_expected.to eq(expected_response_status)
    expect(response.status).to eq(expected_response_status)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    expect(response.body).to include(resource_serializer.new(serializable_resource).to_json)
  end

  it 'should include the expected number of results' do
    is_expected.to eq(expected_response_status)
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('results')
    returned_results = response_json['results']
    expect(returned_results).to be_a(Array)
    expect(returned_results.length).to eq(expected_list_length)
  end

  it 'should not include unexpected resources' do
    expect(unexpected_resources).to be_a(Array)
    is_expected.to eq(expected_response_status)
    unexpected_resources.each do |unexpected_resource|
      expect(response.body).not_to include(resource_serializer.new(unexpected_resource).to_json)
    end
  end
end

shared_examples 'a searchable resource' do
  let(:expected_resources) { [] }
  let(:unexpected_resources) { [] }
  before do
    expect(expected_resources).to be_a(Array)
    expect(unexpected_resources).to be_a(Array)
  end

  it 'should include expected resources' do
    is_expected.to eq(200)
    expected_resources.each do |expected_resource|
      expect(response.body).to include(ActiveModel::Serializer.serializer_for(
        expected_resource).new(expected_resource).to_json)
    end
  end

  it 'should not include unexpected resources' do
    is_expected.to eq(200)
    unexpected_resources.each do |unexpected_resource|
      expect(response.body).not_to include(ActiveModel::Serializer.serializer_for(
        unexpected_resource).new(unexpected_resource).to_json)
    end
  end
end

shared_examples 'a paginated resource' do |payload_sym: :payload, default_per_page: 100, max_per_page: 1000|
  let(:expected_total_length) { resource_class.count }
  let(:page) { 2 }
  let(:per_page) { 1 }
  let(:extras) { FactoryBot.create_list(resource.class.name.downcase.to_sym, 5) }

  let(:pagination_parameters) {
    {
      per_page: per_page,
      page: page
    }
  }

  #paginated_payload must include pagination_parameters
  #if you override it to pass other parameters
  let(:request_payload) {
    send(payload_sym).merge(pagination_parameters)
  }

  let(:expected_response_headers) {{
     'X-Total' => expected_total_length.to_s,
     'X-Total-Pages' => ((expected_total_length.to_f/per_page).ceil).to_s,
     'X-Page' => page.to_s,
     'X-Per-Page' => per_page.to_s,
     'X-Next-Page' => (page+1).to_s,
     'X-Prev-Page' => (page-1).to_s
  }}

  it 'should return pagination response headers' do
     expect(extras.count).to be > per_page
     is_expected.to eq(expected_response_status)
     expect(response.headers.to_h).to include(expected_response_headers)
  end

  it 'should return only per_page results' do
    expect(extras.count).to be > per_page
    is_expected.to eq(expected_response_status)
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('results')
    returned_results = response_json['results']
    expect(returned_results).to be_a(Array)
    expect(returned_results.length).to eq(per_page)
  end

  context 'without per_page parameter' do
    let(:pagination_parameters) {
      {
        page: page
      }
    }
    let(:per_page) { default_per_page }
    let(:page) { 1 }
    let(:expected_response_headers) {{
       'X-Total' => expected_total_length.to_s,
       'X-Total-Pages' => ((expected_total_length.to_f/per_page).ceil).to_s,
       'X-Page' => page.to_s,
       'X-Per-Page' => per_page.to_s,
    }}

    it 'should return default per_page' do
       expect(extras.count).to be > 0
       is_expected.to eq(expected_response_status)
       expect(response.headers.to_h).to include(expected_response_headers)
    end
  end

  context 'when per_page parameter > max_per_page' do
    let(:pagination_parameters) {
      {
        per_page: (max_per_page + 1),
        page: page
      }
    }
    let(:per_page) { max_per_page }
    let(:page) { 1 }
    let(:expected_response_body) { {error: "per_page must be less than #{max_per_page}"}.to_json }

    it 'should return a validation error' do
       expect(extras.count).to be > 0
       is_expected.to eq(400)
       expect(response.body).to eq(expected_response_body)
    end
  end
end

shared_examples 'a sorted index resource' do |expected_last_item_sym|
  let(:expected_last_item) { send(expected_last_item_sym) }
  let(:sort_column) { :created_at }
  let(:sort_order) { "desc" }

  it 'should return a sorted index' do
    is_expected.to eq(expected_response_status)
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('results')
    returned_results = response_json['results']
    expect(returned_results).to be_a(Array)
    expect(returned_results).not_to be_empty
    expect(returned_results.count).to be > 1
    last_date = nil
    returned_results.each do |this_result|
      this_result_object = KindnessFactory.by_kind(this_result["kind"]).find(this_result["id"])
      last_date = this_result_object.send(sort_column) if last_date.nil?

      if sort_order == "asc"
        expect(this_result_object.send(sort_column)).to be >= last_date
      else
        expect(this_result_object.send(sort_column)).to be <= last_date
      end
      last_date = this_result_object.send(sort_column)
    end
  end

  it 'should end with the expected last item' do
    is_expected.to eq(expected_response_status)
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('results')
    returned_results = response_json['results']
    expect(returned_results.last["id"]).to eq(expected_last_item.id)
  end
end

shared_examples 'a creatable resource' do
  let(:expected_response_status) {201}
  let(:new_object) {
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('id')
    resource_class.find(response_json['id'])
  }
  it 'should return success' do
    is_expected.to eq(expected_response_status)
    expect(response.status).to eq(expected_response_status)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
  end

  it 'should be persisted' do
    expect {
      is_expected.to eq(expected_response_status)
    }.to change{resource_class.count}.by(1)
  end

  it 'should return a serialized object' do
    is_expected.to eq(expected_response_status)
    expect(new_object).to be
    expect(response.body).to include(resource_serializer.new(new_object).to_json)
  end
end

shared_examples 'a regeneratable resource' do
  before do
    expect(resource).to be_persisted
  end
  let (:new_resource) {
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key(changed_key.to_s)
    resource_class.where(changed_key => response_json[changed_key.to_s]).take
  }
  let (:changed_key) { :id }

  it 'should return success' do
    is_expected.to eq(200)
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
  end

  it 'should destroy original resource and create a new one' do
    expect {
      is_expected.to eq(200)
    }.not_to change{resource_class.count}
    expect(resource_class.where(changed_key => resource.send(changed_key))).not_to exist
    expect(new_resource).to be
    expect(resource.send(changed_key)).not_to eq(new_resource.send(changed_key))
  end

  it 'should return a serialized resource' do
    is_expected.to eq(200)
    expect(response.body).to include(resource_serializer.new(new_resource).to_json)
  end
end

shared_examples 'a viewable resource' do
  it 'should return a serialized resource' do
    is_expected.to eq(200)
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    expect(response.body).to eq(resource_serializer.new(resource).to_json)
  end
end

shared_examples 'an updatable resource' do
  let(:expected_response_status) { 200 }
  before do
    expect(resource).to be_persisted
  end
  it 'should return success' do
    is_expected.to eq(expected_response_status)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
  end
  it 'should persist changes to resource' do
    resource.reload
    original_attributes = resource.attributes
    expect {
      is_expected.to eq(expected_response_status)
    }.not_to change{resource_class.count}
    resource.reload
    expect(resource.attributes).not_to eq(original_attributes)
    if original_attributes.has_key? "etag"
      expect(resource.etag).not_to eq(original_attributes["etag"])
    end
  end
  it 'should return a serialized resource' do
    is_expected.to eq(expected_response_status)
    resource.reload
    expect(response.body).to include(resource_serializer.new(resource).to_json)
  end
end

shared_examples 'a removable resource' do
  let(:resource_counter) { resource_class }
  let(:expected_count_change) { -1 }

  it 'should return an empty 204 response' do
    is_expected.to eq(204)
    expect(response.status).to eq(204)
    expect(response.body).not_to eq('null')
    expect(response.body).to be
  end
  it 'should remove the resource' do
    expect(resource).to be_persisted
    expect {
      is_expected.to eq(204)
    }.to change{resource_counter.count}.by(expected_count_change)
  end
end

shared_examples 'an authenticated resource' do
  include_context 'without authentication'

  it 'should return a 401 error response' do
    is_expected.to eq(401)
    expect(response.status).to eq(401)
  end
end

shared_examples 'an authorized resource' do
  it 'should return a 403 error response' do
    expect(resource_permission).to be_persisted
    expect(resource_permission.destroy!).to be_truthy
    expect(resource_permission).not_to be_persisted
    is_expected.to eq(403)
    expect(response.status).to eq(403)
  end
end

shared_examples 'a validated resource' do
  let(:expected_reason) { 'validation failed' }
  let(:expected_suggestion) { 'Fix the following invalid fields and resubmit' }
  let(:expects_errors) { true }

  it 'returns a failed response' do
    is_expected.to eq(400)
    expect(response.status).to eq(400)
  end

  it 'returns errors as a JSON payload' do
    is_expected.to eq(400)
    expect(response.body).to be
    expect(response.body).not_to eq('null')

    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('400')
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq(expected_reason)
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq(expected_suggestion)
    if expects_errors
      expect(response_json).to have_key('errors')
      expect(response_json['errors']).to be_a(Array)
      expect(response_json['errors']).not_to be_empty
      response_json['errors'].each do |error|
        expect(error).to have_key('field')
        expect(error).to have_key('message')
      end
    end
  end
end

shared_examples 'an identified resource' do
  let(:expected_suggestion) { "you may have mistyped the #{resource_class} id" }
  it 'should return 404 with error when resource not found with id' do
    is_expected.to eq(404)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('404')
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq("#{resource_class} Not Found")
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq(expected_suggestion)
  end
end

shared_examples 'a client error' do
  let(:expected_response) { 400 }
  let(:expected_reason) { "client has submitted bad data" }
  let(:expected_suggestion) { "Please resubmit with correct data" }

  it 'should return expected error payload' do
    is_expected.to eq(expected_response)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq(expected_response.to_s)
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq(expected_reason)
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq(expected_suggestion)
  end
end

shared_examples 'a kinded resource' do
  it_behaves_like 'a client error' do
    let(:expected_response) { 404 }
    let(:expected_reason) { "object_kind #{resource_kind} Not Supported" }
    let(:expected_suggestion) { "Please supply a supported object_kind" }
  end
end

shared_examples 'an indexed resource' do
  it 'should return 404 with error when kind is not indexed' do
    is_expected.to eq(404)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('404')
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq("object_kind #{resource_class} Not Indexed")
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq("Please supply a supported object_kind")
  end
end

shared_examples 'a logically deleted resource' do
  let(:deleted_resource) { resource }
  it 'should return 404 with error when resource found is logically deleted' do
    expect(deleted_resource).to be_persisted
    expect(deleted_resource).to respond_to 'is_deleted'
    expect(deleted_resource.update_column(:is_deleted, true)).to be_truthy
    is_expected.to eq(404)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('404')
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq("#{deleted_resource.class.name} Not Found")
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq("you may have mistyped the #{deleted_resource.class.name} id")
  end
end

shared_examples 'a software_agent accessible resource' do
  include_context 'with software_agent authentication'
  let(:expected_response_status) {200}
  it 'should return success' do
    is_expected.to eq(expected_response_status)
    expect(response.status).to eq(expected_response_status)
  end
end

shared_examples 'a software_agent restricted resource' do
  include_context 'with software_agent authentication'
  it 'should return forbidden' do
    is_expected.to eq(403)
    expect(response.status).to eq(403)
  end
end

shared_examples 'a feature toggled resource' do |env_key:, env_value: 'true'|
  let(:response_json) { JSON.parse(response.body) }
  let(:expected_response) {{
    'error' => 405,
    'code' => 'not_provided',
    'reason' => 'not implemented',
    'suggestion' => 'this is not the endpoint you are looking for'
  }}
  before do
    ENV[env_key] = env_value
    is_expected.to eq(405)
  end
  after do
    ENV.delete(env_key)
  end
  it { expect(response_json).to eq(expected_response) }
end

shared_examples 'a status error' do |expected_error_sym|
  let(:expected_error) { send(expected_error_sym) }
  it {
    expect(Rails.logger).to receive(:error).with(expected_error)
    get '/api/v1/app/status', params: json_headers
    expect(response.status).to eq(503)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    returned_configs = JSON.parse(response.body)
    expect(returned_configs).to be_a Hash
    expect(returned_configs).to have_key('status')
    expect(returned_configs['status']).to eq('error')
  }
end

shared_examples 'an inconsistent resource' do
  let(:response_json) { JSON.parse(response.body) }
  let(:expected_response) { {
    'error' => '404',
    'code' => "resource_not_consistent",
    'reason' => "resource changes are still being processed by system",
    'suggestion' => "this is a temporary state that will eventually be resolved by the system; please retry request"
  } }
  it 'returns 404 with resource_not_consistent error' do
    is_expected.to eq(404)
    expect { response_json }.not_to raise_error
    expect(response_json).to eq expected_response
  end
end

shared_examples 'an eventually consistent resource' do |eventually_consistent_resource_sym|
  let(:inconsistent_resource) { send(eventually_consistent_resource_sym) }
  it 'should return 404 with error when resource found is not consistent' do
    expect(inconsistent_resource).to be_persisted
    expect(inconsistent_resource).to respond_to 'is_consistent'
    expect(inconsistent_resource.update_column(:is_consistent, false)).to be_truthy
    is_expected.to eq(404)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('404')
    expect(response_json).to have_key('code')
    expect(response_json['code']).to eq("resource_not_consistent")
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq("resource changes are still being processed by system")
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq("this is a temporary state that will eventually be resolved by the system; please retry request")
  end
end

shared_examples 'an eventually consistent upload integrity exception' do |eventually_consistent_upload_sym|
  let(:inconsistent_upload) { send(eventually_consistent_upload_sym) }
  let(:expected_error_message) { "reported size does not match size computed by StorageProvider" }
  before do
    exactly_now = DateTime.now
    expect(inconsistent_upload).to be_persisted
    expect(
      inconsistent_upload.update(
        error_at: exactly_now,
        error_message: expected_error_message,
        is_consistent: true
      )
    ).to be_truthy
  end

  it {
    expect(inconsistent_upload.has_integrity_exception?).to be_truthy
    is_expected.to eq(400)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    response_json = JSON.parse(response.body)
    expect(response_json).to have_key('error')
    expect(response_json['error']).to eq('400')
    expect(response_json).to have_key('code')
    expect(response_json['code']).to eq("not_provided")
    expect(response_json).to have_key('reason')
    expect(response_json['reason']).to eq(expected_error_message)
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq("You must begin a new upload process")
  }
end
