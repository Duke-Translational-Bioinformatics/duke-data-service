require 'rails_helper'

RSpec.describe Graph::Agent do
  before(:example) { resource.create_graph_node }
  subject { resource.graph_model_object }

  context 'User' do
    let(:resource) { FactoryGirl.create(:user) }
    it_behaves_like 'a graphed model'
  end

  context 'SoftwareAgent' do
    let(:resource) { FactoryGirl.create(:software_agent) }
    it_behaves_like 'a graphed model'
  end
end
