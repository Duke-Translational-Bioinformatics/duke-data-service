require 'rails_helper'

RSpec.describe Graph::WasAttributedTo do
  include_context 'mock all Uploads StorageProvider'
  before(:example) { resource.create_graph_relation }
  subject { resource.graph_model_object }
  context 'Attributed To User' do
    let(:resource) { FactoryBot.create(:attributed_to_user_prov_relation) }
    it_behaves_like 'a graphed model'
  end

  context 'Attributed To SoftwareAgent' do
    let(:resource) { FactoryBot.create(:attributed_to_software_agent_prov_relation) }
    it_behaves_like 'a graphed model'
  end
end
