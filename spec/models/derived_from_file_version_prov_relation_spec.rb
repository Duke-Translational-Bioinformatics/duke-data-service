require 'rails_helper'

RSpec.describe DerivedFromFileVersionProvRelation, type: :model do
  subject { FactoryBot.create(:derived_from_file_version_prov_relation) }
  let(:resource_serializer) { DerivedFromFileVersionProvRelationSerializer }
  let(:expected_relationship_type) { 'was-derived-from' }

  include_context 'mock all Uploads StorageProvider'

  it_behaves_like 'a ProvRelation' do
    let(:expected_kind) { 'dds-relation-was-derived-from' }
    let(:serialized_kind) { true }
    let(:kinded_class) { DerivedFromFileVersionProvRelation }
  end

  describe 'validations' do
    include_context 'performs enqueued jobs', only: GraphPersistenceJob
    it { is_expected.to allow_value('FileVersion').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('DataFile').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Container').for(:relatable_from_type) }

    it { is_expected.to allow_value('FileVersion').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('DataFile').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Container').for(:relatable_to_type) }
  end
end
