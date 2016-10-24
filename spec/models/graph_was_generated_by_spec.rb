require 'rails_helper'

RSpec.describe Graph::WasGeneratedBy do
  subject { FactoryGirl.create(:generated_by_activity_prov_relation).create_graph_relation }
  it_behaves_like 'a graphed model'
end
