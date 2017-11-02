require 'rails_helper'

RSpec.describe Graph::FileVersion do
  let(:resource) { FactoryGirl.create(:file_version) }
  before(:example) { resource.create_graph_node }
  subject { resource.graph_model_object }

  it_behaves_like 'a graphed model'
end
