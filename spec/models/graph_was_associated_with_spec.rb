require 'rails_helper'

RSpec.describe Graph::WasAssociatedWith do
  before(:example) { resource.create_graph_relation }
  subject { resource.graph_model_object }
  context 'Associated With User' do
    let(:resource) { FactoryGirl.create(:associated_with_user_prov_relation) }
    it_behaves_like 'a graphed model'
  end

  context 'Associated With SoftwareAgent' do
    let(:resource) { FactoryGirl.create(:associated_with_software_agent_prov_relation) }
    it_behaves_like 'a graphed model'
  end
end
