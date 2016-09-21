require 'rails_helper'

RSpec.describe ProvenanceGraphNode do
  let!(:object) {
    FactoryGirl.create(:file_version, label: "OBJECT")
  }
  let!(:node) { object.graph_node }
  subject{ ProvenanceGraphNode.new(node) }

  it { expect(described_class).to include(ActiveModel::Serialization) }
  it { expect(described_class).to include(Comparable) }

  it { is_expected.to respond_to( "id" ) }
  it { is_expected.to respond_to("node") }
  it { is_expected.to respond_to( "labels" ) }
  it { is_expected.to respond_to( "properties" ) }
  it { is_expected.to respond_to( "properties=" ) }
  it { expect(subject.id).to eq(node.model_id) }
  it { expect(subject.labels).to eq([ "#{ node.class.mapped_label_name }" ]) }
  it { expect(subject.node.model_id).to eq(node.model_id) }
  it {
    expect(subject.properties).to be_nil
    subject.properties = object
    expect(subject.properties).not_to be_nil
    expect(subject.properties).to eq(object)
  }

  context 'initialization' do
    it {
      expect{
        described_class.new
      }.to raise_error(ArgumentError)
    }

    it {
      expect{
        described_class.new(node)
      }.not_to raise_error
    }
  end
end
