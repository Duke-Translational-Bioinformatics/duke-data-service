require 'rails_helper'

RSpec.describe ProvRelation, type: :model do
  describe 'dds-used-relation' do
    subject { FactoryGirl.create(:used_prov_relation) }

    describe 'validations' do
      it { is_expected.to validate_presence_of :creator_id }
      it { is_expected.to validate_presence_of :relatable_from }
      it { is_expected.to validate_presence_of :relationship_type }
      it { is_expected.to validate_presence_of :relatable_to }
    end

    it_behaves_like 'an audited model'
    it_behaves_like 'a kind' do
      let!(:kind_name) { "relation-#{subject.relationship_type}" }
        let(:resource_serializer) { UsedProvRelationSerializer }
    end

    it_behaves_like 'a graphed relation', auto_create: true do
      let(:from_model) { subject.relatable_from }
      let(:to_model) { subject.relatable_to }
      let(:rel_type) { subject.relationship_type.capitalize }
    end
  end
end
