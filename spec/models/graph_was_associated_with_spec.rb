require 'rails_helper'

RSpec.describe Graph::WasAssociatedWith do
  context 'Associated With User' do
    subject { FactoryGirl.create(:associated_with_user_prov_relation).create_graph_relation }
    it_behaves_like 'a graphed model'
  end

  context 'Associated With SoftwareAgent' do
    subject { FactoryGirl.create(:associated_with_software_agent_prov_relation).create_graph_relation }
    it_behaves_like 'a graphed model'
  end
end
