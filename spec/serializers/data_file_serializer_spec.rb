require 'rails_helper'

RSpec.describe DataFileSerializer, type: :serializer do
  let(:resource) { child_file }
  let(:is_logically_deleted) { true }
  let(:root_file) { FactoryGirl.create(:data_file, :root) }
  let(:child_file) { FactoryGirl.create(:data_file, :with_parent) }
  let(:expected_attributes) {{
    'id' => resource.id,
    'parent' => { 'kind' => resource.parent.kind, 'id' => resource.parent_id },
    'name' => resource.name,
    'is_deleted' => resource.is_deleted
  }}

  it_behaves_like 'a has_one association with', :current_file_version, FileVersionPreviewSerializer, root: :current_version
  it_behaves_like 'a has_one association with', :project, ProjectPreviewSerializer
  it_behaves_like 'a has_many association with', :ancestors, AncestorSerializer

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it { is_expected.not_to have_key('upload') }
    it { is_expected.not_to have_key('label') }

    it_behaves_like 'a serializer with a serialized audit'
  end
end
