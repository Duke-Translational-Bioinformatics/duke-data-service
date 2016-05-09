require 'rails_helper'
RSpec.describe UsedProvRelationSerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:used_prov_relation) }
  let(:is_logically_deleted) { true }

  it_behaves_like 'a has_one association with', :relatable_from, ActivitySerializer, root: :from
  it_behaves_like 'a has_one association with', :relatable_to, FileVersionSerializer, root: :to

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('kind')
      expect(subject["kind"]).to eq(resource.kind)
      is_expected.to have_key('id')
      expect(subject['id']).to eq(resource.id)
      is_expected.to have_key('from')
      is_expected.to have_key('to')
    end
    it_behaves_like 'a serializer with a serialized audit'
  end
end
