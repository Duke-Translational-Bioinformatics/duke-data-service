require 'rails_helper'

RSpec.describe Graph::Used do
  subject { FactoryGirl.create(:used_prov_relation).create_graph_relation }
  it_behaves_like 'a graphed model'
end
