require 'rails_helper'

RSpec.describe FolderSerializer, type: :serializer do
  context 'with_parent' do
    let(:folder) { FactoryGirl.create(:folder, :with_parent) }
    it_behaves_like 'a serialized Folder', :folder, with_parent: true
  end

  context 'without_parent' do
    let(:folder) { FactoryGirl.create(:folder, :root) }
    it_behaves_like 'a serialized Folder', :folder
  end
end
