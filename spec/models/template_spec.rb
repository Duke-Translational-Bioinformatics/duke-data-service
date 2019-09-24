require 'rails_helper'

RSpec.describe Template, type: :model do
  let(:good_names) {[
    'sequencing_file_info',
    Faker::Internet.slug(words: nil, glue: '_')
  ]}
  let(:bad_names) {[
    Faker::Name.name,
    Faker::Internet.email,
    Faker::Internet.url,
    Faker::SlackEmoji.emoji,
    "#{Faker::Internet.slug(words: nil, glue: '_')}\n#{Faker::Internet.slug(words: nil, glue: '_')}"
  ]}

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:creator).class_name('User') }
    it { is_expected.to have_many(:properties) }
    it { is_expected.to have_many(:meta_templates) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:creator) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to allow_values(*good_names).for(:name) }
    it { is_expected.not_to allow_values(*bad_names).for(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(60) }

    context 'after creation' do
      subject { FactoryBot.create(:template) }

      context 'without meta_templates' do
        it { expect(subject.meta_templates).to be_empty }
        it { is_expected.to allow_values(*good_names).for(:name) }
        it { expect(subject.destroy).to be_truthy }
      end

      context 'with meta_templates' do
        before { FactoryBot.create(:meta_template, template: subject) }
        it { expect(subject.meta_templates).not_to be_empty }
        it { is_expected.not_to allow_values(*good_names).for(:name) }
        it { expect(subject.destroy).to be_falsey }
      end
    end
  end
end
