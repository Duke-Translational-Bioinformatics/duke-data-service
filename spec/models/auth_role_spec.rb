require 'rails_helper'

RSpec.describe AuthRole, type: :model do
  describe 'validations' do
    subject {FactoryGirl.create(:auth_role)}

    it 'should require a unique id' do
      should validate_presence_of(:id)
      should validate_uniqueness_of(:id)
    end

    it 'should require a name' do
      should validate_presence_of(:name)
    end

    it 'should require a description' do
      should validate_presence_of(:description)
    end

    it 'should require at least one permission' do
      should validate_presence_of(:permissions)
      should allow_value(['foo']).for(:permissions)
      should allow_value(['foo', 'bar']).for(:permissions)
      should_not allow_value([]).for(:permissions)
    end

    it 'should require at least one context' do
      should validate_presence_of(:contexts)
      should allow_value(['foo']).for(:contexts)
      should allow_value(['foo', 'bar']).for(:contexts)
      should_not allow_value([]).for(:contexts)
    end
  end

  describe 'queries' do
    let(:query_context) {'findme'}
    let!(:with_context) { FactoryGirl.create_list(:auth_role, 5, contexts: [query_context]) }
    let!(:others) { FactoryGirl.create_list(:auth_role, 5) }

    it 'should support with_context' do
      expect(AuthRole).to respond_to 'with_context'
      found_with_context = AuthRole.with_context(query_context)
      expect(found_with_context.count).to eq(with_context.length)
      found_with_context.each do |ar|
        expect(ar.contexts).to include(query_context)
      end
    end
  end
end
