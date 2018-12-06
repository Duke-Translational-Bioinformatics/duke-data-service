require 'rails_helper'

RSpec.describe InvalidatedByActivityProvRelation, type: :model do
  include_context 'mock all Uploads StorageProvider'
  subject { FactoryBot.create(:invalidated_by_activity_prov_relation) }
  let(:resource_serializer) { InvalidatedByActivityProvRelationSerializer }
  let(:expected_relationship_type) { 'was-invalidated-by' }

  it_behaves_like 'a ProvRelation' do
    let(:expected_kind) { 'dds-relation-was-invalidated-by' }
    let(:serialized_kind) { true }
    let(:kinded_class) { InvalidatedByActivityProvRelation }
  end

  describe 'validations' do
    include_context 'performs enqueued jobs', only: GraphPersistenceJob
    it { is_expected.to allow_value('FileVersion').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('DataFile').for(:relatable_from_type) }
    it { is_expected.not_to allow_value('Container').for(:relatable_from_type) }

    it { is_expected.to allow_value('Activity').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('User').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('Project').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('FileVersion').for(:relatable_to_type) }
    it { is_expected.not_to allow_value('SoftwareAgent').for(:relatable_to_type) }

    describe 'undeleted FileVersion' do
      before do
        subject.relatable_from.update_attribute(:is_deleted, false)
      end
      it { is_expected.not_to be_valid }
    end
  end
end
