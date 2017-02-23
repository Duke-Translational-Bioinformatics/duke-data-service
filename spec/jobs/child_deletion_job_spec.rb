require 'rails_helper'

RSpec.describe ChildDeletionJob, type: :job do
  context 'project' do
    let(:project) { FactoryGirl.create(:project) }
    let(:root_folder) { FactoryGirl.create(:folder, :root, project: project) }
    let(:root_file) { FactoryGirl.create(:data_file, :root, project: project) }

    it_behaves_like 'a ChildDeletionJob', :project, :root_folder, :root_file
  end

  context 'folder' do
    let(:folder) { FactoryGirl.create(:folder) }
    let(:sub_folder) { FactoryGirl.create(:folder, parent: folder) }
    let(:sub_file) { FactoryGirl.create(:data_file, parent: folder) }

    it_behaves_like 'a ChildDeletionJob', :folder, :sub_folder, :sub_file
  end
end
