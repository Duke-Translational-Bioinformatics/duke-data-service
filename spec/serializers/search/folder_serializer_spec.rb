require 'rails_helper'

RSpec.describe Search::FolderSerializer, type: :serializer do
  let(:extra_searchable_attributes) {{
    'created_at' => folder.created_at.as_json,
    'updated_at' => folder.updated_at.as_json,
    'label' => folder.label
  }}

  context 'with_parent' do
    let(:folder) { FactoryGirl.create(:folder, :with_parent) }
    it_behaves_like 'a serialized Folder', :folder, with_parent: true do
      it_behaves_like 'a has_one association with', :creator, Search::UserSummarySerializer
      it_behaves_like 'a json serializer' do
        it { is_expected.to include(extra_searchable_attributes) }
      end
    end
  end

  context 'without_parent' do
    let(:folder) { FactoryGirl.create(:folder, :root) }
    it_behaves_like 'a serialized Folder', :folder do
      it_behaves_like 'a has_one association with', :creator, Search::UserSummarySerializer
      it_behaves_like 'a json serializer' do
        it { is_expected.to include(extra_searchable_attributes) }
      end
    end
  end
end
