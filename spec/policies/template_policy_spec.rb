require 'rails_helper'

describe TemplatePolicy do
  include_context 'policy declarations'

  let(:template) { FactoryBot.create(:template) }
  let(:other_template) { FactoryBot.create(:template) }

  it_behaves_like 'system_permission can access', :template
  it_behaves_like 'system_permission can access', :other_template
  
  context 'when user is a template creator' do
    let(:user) { template.creator }

    describe '.scope' do
      it { expect(resolved_scope).to include(template) }
      it { expect(resolved_scope).to include(other_template) }
    end
    permissions :create?, :update?, :destroy? do
      it { is_expected.to permit(user, template) }
      it { is_expected.not_to permit(user, other_template) }
    end
    permissions :index?, :show? do
      it { is_expected.to permit(user, template) }
      it { is_expected.to permit(user, other_template) }
    end
  end
end
