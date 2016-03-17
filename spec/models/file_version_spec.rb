require 'rails_helper'

RSpec.describe FileVersion, type: :model do
  subject { file_version }
  let(:file_version) { FactoryGirl.create(:file_version) }
  let(:deleted_file_version) { FactoryGirl.create(:file_version, :deleted) }
  let(:uri_encoded_name) { URI.encode(subject.data_file.name) }

  it_behaves_like 'an audited model'
  it_behaves_like 'a kind' do
    let!(:kind_name) { 'file-version' }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:data_file) }
    it { is_expected.to belong_to(:upload) }
    it { is_expected.to belong_to(:creator) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :upload_id }
    it { is_expected.to validate_presence_of :creator_id }

    it 'should allow is_deleted to be set' do
      should allow_value(true).for(:is_deleted)
      should allow_value(false).for(:is_deleted)
    end

    context 'when #is_deleted=true' do
      subject { deleted_file_version }
      it { is_expected.not_to validate_presence_of(:upload_id) }
      it { is_expected.not_to validate_presence_of(:creator_id) }
    end
  end

  describe 'instance methods' do
    it { should delegate_method(:name).to(:data_file) }
    it { should delegate_method(:http_verb).to(:upload) }
    it { should delegate_method(:host).to(:upload).as(:url_root) }
    it { should delegate_method(:url).to(:upload).as(:temporary_url) }

    describe '#url' do
      it { expect(subject.url).to include uri_encoded_name }
    end
  end
end
