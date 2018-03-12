require 'rails_helper'

RSpec.describe Graph::Activity do
  let(:resource) { FactoryBot.create(:activity) }
  before(:example) { resource.create_graph_node }
  subject { resource.graph_model_object }
  it_behaves_like 'a graphed model' do
    it_behaves_like 'a Graphed::NodeModel'
  end
end
