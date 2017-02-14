require 'rails_helper'

describe DDS::V1::Base do
  let(:path) {"/api_base_test"}
  let(:dummy) do
    dummy_path = path
    Class.new(Grape::API) do
      helpers do
        def override_helper; end
      end
      get dummy_path do
        override_helper
      end
    end
  end
  before do
    described_class.mount dummy
  end

  let(:url) {"/api/v1" + path }
  subject { get(url) }

  context 'when Rack::Timeout raises Rack::Timeout::RequestTimeoutError' do
    before do
      Grape::Endpoint.before_each do |endpoint|
        expect(endpoint).to receive(:override_helper).and_raise(Rack::Timeout::RequestTimeoutError, ENV)
      end
    end
    after { Grape::Endpoint.before_each nil }
    it 'should return a 503' do
      is_expected.to eq 503
      expect(response.body).to include('Request Timeout')
    end
  end
end
