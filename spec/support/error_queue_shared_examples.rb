shared_context 'error queue message utilities' do
  def stub_message_response(payload, routing_key)
    id = Digest::SHA256.hexdigest(payload)
    {id: id, payload: payload, routing_key: routing_key}
  end
end
