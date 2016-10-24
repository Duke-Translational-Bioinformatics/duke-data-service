require 'rails_helper'

RSpec.describe Graph::WasAttributedTo do
  context 'Attributed To User' do
    subject { FactoryGirl.create(:attributed_to_user_prov_relation).create_graph_relation }
    it_behaves_like 'a graphed model'
  end

  context 'Attributed To SoftwareAgent' do
    subject { FactoryGirl.create(:attributed_to_software_agent_prov_relation).create_graph_relation }
    it_behaves_like 'a graphed model'
  end
end
