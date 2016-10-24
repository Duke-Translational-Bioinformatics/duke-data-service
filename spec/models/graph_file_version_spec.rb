require 'rails_helper'

RSpec.describe Graph::Activity do
  subject { FactoryGirl.create(:file_version).create_graph_node }
  it_behaves_like 'a graphed model'
end
