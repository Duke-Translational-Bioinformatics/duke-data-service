require 'rails_helper'

RSpec.describe Graph::WasDerivedFrom do
  let(:resource) { FactoryGirl.create(:derived_from_file_version_prov_relation) }
  before(:example) { resource.create_graph_relation }
  subject { resource.graph_model_object }
  it_behaves_like 'a graphed model'
end
