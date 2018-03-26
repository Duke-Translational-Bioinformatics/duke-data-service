require 'rails_helper'

RSpec.describe UserSerializer, type: :serializer do
  let(:user_authentication_service) { FactoryBot.create(:user_authentication_service, :populated) }
  let(:resource) { user_authentication_service.user }
  let(:is_logically_deleted) { false }
  let(:expected_attributes) {{
    'id' => resource.id,
    'username' => resource.username,
    'full_name' => resource.display_name,
    'first_name' => resource.first_name,
    'last_name' => resource.last_name,
    'email' => resource.email,
    'auth_provider' => { 'uid' => user_authentication_service.uid,
                         'source' => user_authentication_service.authentication_service.name
                       },
    'last_login_on' => resource.last_login_at.as_json,
    'agent' => nil
  }}
  it_behaves_like 'a has_one association with', :current_software_agent, SoftwareAgentPreviewSerializer, root: :agent

  it_behaves_like 'a json serializer' do
    it { is_expected.to include(expected_attributes) }
    it_behaves_like 'a serializer with a serialized audit'

    context 'with current_software_agent' do
      before do
        resource.current_software_agent = FactoryBot.create(:software_agent)
      end
      it { expect(subject['agent']).not_to be_nil }
    end
  end
end
