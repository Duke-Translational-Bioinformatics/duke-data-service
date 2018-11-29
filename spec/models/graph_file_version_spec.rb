require 'rails_helper'

RSpec.describe Graph::FileVersion do
  include_context 'mock all Uploads StorageProvider'
  let(:resource) { FactoryBot.create(:file_version) }
  before(:example) { resource.create_graph_node }
  subject { resource.graph_model_object }

  it_behaves_like 'a graphed model' do
    it_behaves_like 'a Graphed::NodeModel'
  end
end
