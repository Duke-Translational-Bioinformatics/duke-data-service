shared_context 'common headers' do
  let(:common_headers) { { 'Accept' => 'application/json', 'Content-Type' => 'application/json'} }
end

shared_context 'without authentication' do
  include_context 'common headers'
  let(:headers) { common_headers }
end

shared_context 'with authentication' do
  include_context 'common headers'
  let(:user_auth) { FactoryGirl.create(:user_authentication_service, :populated) }
  let(:current_user) { user_auth.user }
  let (:api_token) { user_auth.api_token }
  let(:headers) {{'Authorization' => api_token}.merge(common_headers)}
end

shared_examples 'a listable resource' do
  it 'should return a list that includes a serialized resource' do
    expect(resource).to be_persisted
    is_expected.to eq(200)
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    expect(response.body).to include(resource_serializer.new(resource).to_json)
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
  before do
    expect(resource).to be_persisted
  end
  it 'should return success' do
    is_expected.to eq(200)
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
  end
  it 'should persist changes to resource' do
    resource.reload
    original_attributes = resource.attributes
    expect {
      is_expected.to eq(200)
    }.not_to change{resource_class.count}
    resource.reload
    expect(resource.attributes).not_to eq(original_attributes)
  end
  it 'should return a serialized resource' do
    is_expected.to eq(200)
    resource.reload
    expect(response.body).to include(resource_serializer.new(resource).to_json)
  end
end

shared_examples 'a removable resource' do
  let(:resource_counter) { resource_class }

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
    }.to change{resource_counter.count}.by(-1)
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
    expect(response_json['reason']).to eq('validation failed')
    expect(response_json).to have_key('suggestion')
    expect(response_json['suggestion']).to eq('Fix the following invalid fields and resubmit')
    expect(response_json).to have_key('errors')
    expect(response_json['errors']).to be_a(Array)
    expect(response_json['errors']).not_to be_empty
    response_json['errors'].each do |error|
      expect(error).to have_key('field')
      expect(error).to have_key('message')
    end
  end
end

shared_examples 'an identified resource' do
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
    expect(response_json['suggestion']).to eq("you may have mistyped the #{resource_class} id")
  end
end
