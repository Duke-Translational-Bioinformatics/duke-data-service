require 'rails_helper'

RSpec.describe NonChunkedUpload, type: :model do
  it { is_expected.to be_an Upload }
end
