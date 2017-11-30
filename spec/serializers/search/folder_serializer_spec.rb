require 'rails_helper'

RSpec.describe Search::FolderSerializer, type: :serializer do

  let(:folder) { FactoryGirl.create(:folder) }
  it_behaves_like 'a serialized Folder', :folder do
    it_behaves_like 'a json serializer'
  end
end
