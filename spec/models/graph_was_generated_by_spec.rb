require 'rails_helper'

RSpec.describe Graph::WasGeneratedBy do
  let(:resource) { FactoryGirl.create(:generated_by_activity_prov_relation) }
  before(:example) { resource.create_graph_relation }
  subject { resource.graph_model_object }
  it_behaves_like 'a graphed model'
end
