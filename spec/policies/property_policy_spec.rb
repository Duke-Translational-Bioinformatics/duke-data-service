require 'rails_helper'

describe PropertyPolicy do
  include_context 'policy declarations'

  let(:template) { FactoryGirl.create(:template) }
  let(:property) { FactoryGirl.create(:property, template: template) }
  let(:other_property) { FactoryGirl.create(:property) }

  it_behaves_like 'system_permission can access', :property
  it_behaves_like 'system_permission can access', :other_property
  
  context 'when user is a template creator' do
    let(:user) { template.creator }

    describe '.scope' do
      it { expect(resolved_scope).to include(property) }
      it { expect(resolved_scope).to include(other_property) }
    end
    permissions :create?, :update?, :destroy? do
      it { is_expected.to permit(user, property) }
      it { is_expected.not_to permit(user, other_property) }
    end
    permissions :index?, :show? do
      it { is_expected.to permit(user, property) }
      it { is_expected.to permit(user, other_property) }
    end
  end
end
