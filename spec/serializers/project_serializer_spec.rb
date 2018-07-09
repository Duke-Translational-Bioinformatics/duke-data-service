require 'rails_helper'

RSpec.describe ProjectSerializer, type: :serializer do
  let(:resource) { FactoryBot.create(:project, :with_slug) }
  let(:is_logically_deleted) { true }
  let(:expected_attributes) {{
    'id' => resource.id,
    'name' => resource.name,
    'slug' => resource.slug,
    'description' => resource.description,
    'is_deleted' => resource.is_deleted
  }}

  before do
    ChildDeletionJob.job_wrapper.new.run
    ChildDeletionJob.job_wrapper.new.stop
  end

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'
  end
end
