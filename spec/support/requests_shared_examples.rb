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
