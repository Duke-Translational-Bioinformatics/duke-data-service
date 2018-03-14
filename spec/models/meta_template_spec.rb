require 'rails_helper'

RSpec.describe MetaTemplate, type: :model do
  subject { FactoryBot.create(:meta_template) }
  let(:templatable_classes) {[
    Activity,
    DataFile
  ]}
  let(:file) { FactoryBot.create(:data_file) }
  let(:meta_template) { FactoryBot.create(:meta_template) }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:templatable).touch(true) }
    it { is_expected.to belong_to(:template) }
    it { is_expected.to have_many(:meta_properties).autosave(true).dependent(:destroy) }
  end

  describe 'validations' do
    let!(:existing_tag_for_uniqueness_validation) { FactoryBot.create(:meta_template, :skip_validation, templatable: file) }
    it { is_expected.to validate_presence_of(:templatable) }
    it { is_expected.to validate_presence_of(:template) }
    it 'restrict templatable_type to templatable_classes' do
      is_expected.to allow_value(file).for(:templatable)
      is_expected.not_to allow_value(meta_template).for(:templatable)
    end
    it { is_expected.to validate_uniqueness_of(:template).scoped_to(:templatable_id).case_insensitive }
  end

  describe '#project_permissions' do
    it { is_expected.to respond_to(:project_permissions) }
    it { expect(subject.project_permissions).to eq(subject.templatable.project_permissions) }
  end

  describe '::templatable_classes' do
    it { expect(described_class).to respond_to(:templatable_classes) }
    it { expect(described_class.templatable_classes).to match_array(templatable_classes)}
  end

  describe '#save' do
    let(:template) { FactoryBot.create(:template) }
    let(:templatable) { FactoryBot.create(:data_file) }
    let(:meta_templates) { FactoryBot.build_list(:meta_template, 4, template: template, templatable: templatable) }
    include_context 'with job runner', ProjectStorageProviderInitializationJob
    include_context 'with concurrent calls', object_list: :meta_templates, method: :save
    it { expect(MetaTemplate.count).to eq(1) }
  end
end
