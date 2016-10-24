require 'rails_helper'

RSpec.describe FolderSerializer, type: :serializer do
  let(:resource) { child_folder }
  let(:is_logically_deleted) { true }
  let(:child_folder) { FactoryGirl.create(:folder, :with_parent) }
  let(:root_folder) { FactoryGirl.create(:folder, :root) }
  let(:expected_attributes_with_parent) {{
    'id' => resource.id,
    'parent' => { 'kind' => resource.parent.kind, 'id' => resource.parent.id },
    'name' => resource.name,
    'is_deleted' => resource.is_deleted
  }}
  let(:expected_attributes_without_parent) {{
    'parent' => { 'kind' => resource.project.kind, 'id' => resource.project.id }
  }}
  
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_many association with', :ancestors, AncestorSerializer

  it_behaves_like 'a json serializer' do
    context 'with a parent' do
      it { is_expected.to include(expected_attributes_with_parent) }
    end

    context 'without a parent' do
      let(:resource) { root_folder }
      it { is_expected.to include(expected_attributes_without_parent) }
    end
  end
end
