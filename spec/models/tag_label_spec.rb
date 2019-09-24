require 'rails_helper'

RSpec.describe TagLabel, type: :model do

  it { expect(described_class).to include(ActiveModel::Model) }
  it { expect(described_class).to include(ActiveModel::Serialization) }
  it { expect(described_class).to include(Comparable) }

  it { is_expected.to respond_to(:label) }
  it { is_expected.to respond_to(:label=) }
  it { is_expected.to respond_to(:count) }
  it { is_expected.to respond_to(:count=) }
  it { is_expected.to respond_to(:last_used_on) }
  it { is_expected.to respond_to(:last_used_on=) }
  
  describe '#attributes' do
    subject { TagLabel.new(label: 'Foo', count: 4, last_used_on: Faker::Time.backward(days: 1)) }
    let(:attributes) { {'label'=>'Foo', 'count'=>4} }
    it { is_expected.to respond_to(:attributes) }
    it { expect(subject.attributes).to eq(attributes) }
  end

  describe '#<=>' do
    subject { TagLabel.new(label: 'Foo', count: 4, last_used_on: last_used_on) }
    let(:last_used_on) { Faker::Time.backward(days: 1) }
    let(:same) { TagLabel.new(label: 'Foo', count: 4, last_used_on: last_used_on) }
    let(:different_label) { TagLabel.new(label: 'Bar', count: 4, last_used_on: last_used_on) }
    let(:different_count) { TagLabel.new(label: 'Foo', count: 1, last_used_on: last_used_on) }
    let(:different_last_used_on) { TagLabel.new(label: 'Foo', count: 4, last_used_on: Faker::Time.forward(days: 1)) }

    it { is_expected.to eq(same) }
    it { is_expected.not_to eq(different_label) }
    it { is_expected.not_to eq(different_count) }
    it { is_expected.to eq(different_last_used_on) }
  end
end
