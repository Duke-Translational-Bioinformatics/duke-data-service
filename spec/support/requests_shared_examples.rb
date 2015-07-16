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
    get url, nil, headers
    expect(response.status).to eq(200)
    expect(response.body).to be
    expect(response.body).not_to eq('null')
    expect(response.body).to include(resource_serializer.new(resource).to_json)
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

shared_examples 'a removable resource' do
  it 'remove the resource and return an empty 204 response' do
    expect(resource).to be_persisted
    expect {
      delete url, nil, headers
      expect(response.status).to eq(204)
      expect(response.body).not_to eq('null')
      expect(response.body).to be
    }.to change{resource_class.count}.by(-1)
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
