require 'rails_helper'
RSpec.describe ActivitySerializer, type: :serializer do
  let(:resource) { FactoryGirl.create(:activity) }
  let(:is_logically_deleted) { true }

  it_behaves_like 'a json serializer' do
    it 'should have expected keys and values' do
      is_expected.to have_key('id')
      expect(subject['id']).to eq(resource.id)
      is_expected.to have_key 'name'
      expect(subject['name']).to eq(resource.name)
      is_expected.to have_key 'description'
      expect(subject['description']).to eq(resource.description)
      is_expected.to have_key 'started_on'
      expect(DateTime.parse(subject['started_on']).to_i).to eq(resource.started_on.to_i)
      is_expected.to have_key 'ended_on'
      expect(DateTime.parse(subject['ended_on']).to_i).to eq(resource.ended_on.to_i)
      is_expected.to have_key 'is_deleted'
      expect(subject['is_deleted']).to eq(resource.is_deleted)
    end
    it_behaves_like 'a serializer with a serialized audit'
  end
end
