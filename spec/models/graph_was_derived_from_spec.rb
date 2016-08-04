require 'rails_helper'

RSpec.describe Graph::WasDerivedFrom do
  subject { FactoryGirl.create(:derived_from_file_version_prov_relation).create_graph_relation }
  it_behaves_like 'a graphed model'
end
