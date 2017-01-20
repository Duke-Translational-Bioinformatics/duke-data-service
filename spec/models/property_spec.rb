require 'rails_helper'

RSpec.describe Property, type: :model do
  let(:good_keys) {[
    'output_type',
    Faker::Name.first_name
  ]}
  let(:bad_keys) {[
    Faker::Name.name,
    Faker::Internet.email,
    Faker::Internet.url,
    Faker::SlackEmoji.emoji,
    "#{Faker::Name.first_name}\n#{Faker::Name.first_name}"
  ]}

  let(:elastic_core_data_types) {[
    'string',
    'long',
    'integer',
    'short',
    'byte',
    'double',
    'float',
    'date',
    'boolean',
    'binary'
  ]}

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:template) }
    it { is_expected.to have_many(:meta_properties) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:description) }
    it { is_expected.to validate_presence_of(:data_type) }

    it { is_expected.to validate_length_of(:key).is_at_most(60) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:template_id).case_insensitive }
    it { is_expected.to allow_values(*good_keys).for(:key) }
    it { is_expected.not_to allow_values(*bad_keys).for(:key) }
    it { is_expected.to validate_inclusion_of(:data_type).in_array(elastic_core_data_types) }

    context 'after creation' do
      subject { FactoryGirl.create(:property) }

      context 'without meta_properties' do
        it { expect(subject.meta_properties).to be_empty }
        it { is_expected.to allow_values(*good_keys).for(:key) }
        it { is_expected.to allow_value(elastic_core_data_types.last).for(:data_type) }
        it { expect(subject.destroy).to be_truthy }
      end

      context 'with meta_properties' do
        include_context 'elasticsearch prep', [:meta_property, :subject, :meta_template], [:templatable]
        let(:templatable) { FactoryGirl.create(:data_file) }
        let(:meta_template) { FactoryGirl.create(:meta_template, templatable: templatable)}
        let(:meta_property) { FactoryGirl.create(:meta_property, meta_template: meta_template, property: subject) }

        it { expect(subject.meta_properties).not_to be_empty }
        it { is_expected.not_to allow_values(*good_keys).for(:key) }
        it { is_expected.not_to allow_value(elastic_core_data_types.last).for(:data_type) }
        it { expect(subject.destroy).to be_falsey }
      end
    end
  end
end
