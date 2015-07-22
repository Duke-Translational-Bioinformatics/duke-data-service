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
  subject { get url, nil, headers }

  it 'should return a list that includes a serialized resource' do
    is_expected.to eq(200)
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    expect(response.body).to include(resource_serializer.new(resource).to_json)
  end
end

shared_examples 'a creatable resource' do
  subject { post url, payload.to_json, headers }

  it 'should return success' do
    is_expected.to eq(201)
    expect(response.status).to eq(201)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
  end

  it 'should be persisted' do
    expect {
      subject
    }.to change{resource_class.count}.by(1)
  end
end

shared_examples 'a viewable resource' do
  it 'should return a serialized resource' do
    get url, nil, headers
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    expect(response.body).to eq(resource_serializer.new(resource).to_json)
  end
end

shared_examples 'an updatable resource' do
  subject {put url, payload.to_json, headers}

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
  subject { delete url, nil, headers }
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

shared_examples 'a failed DELETE request' do
  it 'should require an auth token' do
    delete url, nil, headers
    expect(response.status).to eq(400)
  end
end

shared_examples 'a failed GET request' do
  it 'should require an auth token' do
    get url, nil, headers
    expect(response.status).to eq(400)
  end
end

shared_examples 'a failed PUT request' do
  it 'should require an auth token' do
    put url, payload.to_json, headers
    expect(response.status).to eq(400)
  end
end

shared_examples 'a failed POST request' do
  it 'should require an auth token' do
    expect {
      post url, payload.to_json, headers
      expect(response.status).to eq(400)
    }.not_to change{resource_class.count}
  end
end

shared_examples 'a validation failure' do
  it 'returns errors as a JSON payload' do
    expect(response.status).to eq(400)
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
