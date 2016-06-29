require 'rails_helper'

RSpec.describe TagLabel, type: :model do

  it { expect(described_class).to include(ActiveModel::Model) }
  it { expect(described_class).to include(ActiveModel::Serialization) }
  it { expect(described_class).to include(Comparable) }

  it { is_expected.to respond_to(:label) }
  it { is_expected.to respond_to(:label=) }
  it { is_expected.to respond_to(:count) }
  it { is_expected.to respond_to(:count=) }
  
  describe '#attributes' do
    subject { TagLabel.new(label: 'Foo', count: 4) }
    let(:attributes) { {'label'=>'Foo', 'count'=>4} }
    it { is_expected.to respond_to(:attributes) }
    it { expect(subject.attributes).to eq(attributes) }
  end

  describe '#<=>' do
    subject { TagLabel.new(label: 'Foo', count: 4) }
    let(:same) { TagLabel.new(label: 'Foo', count: 4) }
    let(:different_label) { TagLabel.new(label: 'Bar', count: 4) }
    let(:different_count) { TagLabel.new(label: 'Foo', count: 1) }

    it { is_expected.to eq(same) }
    it { is_expected.not_to eq(different_label) }
    it { is_expected.not_to eq(different_count) }
  end
end
