require 'rails_helper'

RSpec.describe Graph::Activity do
  subject { FactoryGirl.create(:activity).create_graph_node }
  it_behaves_like 'a graphed model'
end
