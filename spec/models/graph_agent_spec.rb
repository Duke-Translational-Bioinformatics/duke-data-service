require 'rails_helper'

RSpec.describe Graph::Activity do
  context 'User' do
    subject { FactoryGirl.create(:user).create_graph_node }
    it_behaves_like 'a graphed model'
  end

  context 'SoftwareAgent' do
    subject { FactoryGirl.create(:software_agent).create_graph_node }
    it_behaves_like 'a graphed model'
  end
end
