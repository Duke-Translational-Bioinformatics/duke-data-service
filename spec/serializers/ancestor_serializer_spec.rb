require 'rails_helper'

RSpec.describe AncestorSerializer, type: :serializer do
  let(:folder) { FactoryGirl.create(:folder) }
  let(:project) { FactoryGirl.create(:project) }

  context 'with Folder resource' do
    let(:resource) { folder }

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('kind')
        is_expected.to have_key('id')
        is_expected.to have_key('name')

        expect(subject['id']).to eq(resource.id)
        expect(subject['kind']).to eq(resource.kind)
        expect(subject['name']).to eq(resource.name)
      end
    end
  end

  context 'with Project resource' do
    let(:resource) { project }

    it_behaves_like 'a json serializer' do
      it 'should have expected keys and values' do
        is_expected.to have_key('kind')
        is_expected.to have_key('id')
        is_expected.to have_key('name')

        expect(subject['id']).to eq(resource.id)
        expect(subject['kind']).to eq(resource.kind)
        expect(subject['name']).to eq(resource.name)
      end
    end
  end
end
