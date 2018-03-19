require 'rails_helper'

describe '/api/v1/swagger_doc' do
  subject { get '/api/v1/swagger_doc' }

  it { is_expected.to be 200 }
end
