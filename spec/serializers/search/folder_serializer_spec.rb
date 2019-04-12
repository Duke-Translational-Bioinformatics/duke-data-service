require 'rails_helper'

RSpec.describe Search::FolderSerializer, type: :serializer do
  let(:folder) { FactoryBot.create(:folder) }

  it_behaves_like 'a serialized Folder', :folder do
    it_behaves_like 'a json serializer'
  end
end
