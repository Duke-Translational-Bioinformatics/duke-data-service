require 'rails_helper'

RSpec.describe MetaProperty, type: :model do
  let(:meta_template) { FactoryGirl.create(:meta_template) }
  let(:property) { FactoryGirl.create(:property, template: meta_template.template) }
  let(:other_property) { FactoryGirl.create(:property) }

  it_behaves_like 'an audited model'

  describe 'associations' do
    it { is_expected.to belong_to(:meta_template) }
    it { is_expected.to belong_to(:property) }
  end

  describe 'callbacks' do
    it { is_expected.to callback(:set_property_from_key).before(:validation) }
  end

  describe 'validations' do
    let!(:existing_tag_for_uniqueness_validation) { FactoryGirl.create(:meta_property) }

    it { is_expected.to validate_presence_of(:meta_template) }
    it { is_expected.to validate_presence_of(:property) }
    it { is_expected.to validate_presence_of(:value) }

    it { is_expected.to validate_uniqueness_of(:property).scoped_to(:meta_template_id).case_insensitive }

    context 'when a meta_template is set' do
      subject { FactoryGirl.build(:meta_property, meta_template: meta_template) }

      it { is_expected.to allow_value(nil).for(:key) }
      it { is_expected.to allow_value(property.key).for(:key) }
      it { is_expected.not_to allow_value(other_property.key).for(:key) }
    end

    context 'when a meta_template is nil' do
      subject { FactoryGirl.build(:meta_property, meta_template: nil) }

      it { is_expected.to allow_value(nil).for(:key) }
      it { is_expected.not_to allow_value(property.key).for(:key) }
      it { is_expected.not_to allow_value(other_property.key).for(:key) }
    end
  end

  it { is_expected.to respond_to(:key) }
  it { is_expected.to respond_to(:key=).with(1).argument }

  describe '#set_property_from_key' do
    it { is_expected.to respond_to(:set_property_from_key) }

    context 'called' do
      before { expect{subject.set_property_from_key}.not_to raise_error }

      context 'when key is nil' do
        subject { FactoryGirl.build(:meta_property, meta_template: meta_template, property: property, key: nil) }

        it { expect(subject.key).to be_nil }
        it { expect(subject.property).to eq(property) }
      end

      context 'when meta_template is nil' do
        subject { FactoryGirl.build(:meta_property, meta_template: nil, key: property.key) }

        it { expect(subject.key).to eq(property.key) }
        it { expect(subject.meta_template).to be_nil }
        it { expect(subject.property).to be_nil }
      end

      context 'when key is a property from another template' do
        subject { FactoryGirl.build(:meta_property, meta_template: meta_template, key: other_property.key) }

        it { expect(subject.key).to eq(other_property.key) }
        it { expect(subject.meta_template).to eq(meta_template) }
        it { expect(subject.property).to be_nil }
      end

      context 'when key is a property from the assigned template' do
        subject { FactoryGirl.build(:meta_property, meta_template: meta_template, key: property.key) }

        it { expect(subject.key).to eq(property.key) }
        it { expect(subject.meta_template).to eq(meta_template) }
        it { expect(subject.property).to eq(property) }
      end
    end
  end
end
