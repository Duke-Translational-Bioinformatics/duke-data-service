require 'rails_helper'

RSpec.describe ProvenanceGraphNode do
  include_context 'mock all Uploads StorageProvider'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob
  let!(:object) {
    FactoryBot.create(:file_version, label: "OBJECT")
  }
  let!(:node) { object.graph_node }
  subject{ ProvenanceGraphNode.new(node) }

  it { expect(described_class).to include(ActiveModel::Serialization) }
  it { expect(described_class).to include(Comparable) }

  it { is_expected.to respond_to( "id" ) }
  it { is_expected.to respond_to("node") }
  it { is_expected.to respond_to( "labels" ) }
  it { is_expected.to respond_to( "properties" ) }
  it { is_expected.to respond_to( "restricted" ) }
  it { is_expected.to respond_to("restricted=") }
  it { is_expected.to respond_to("is_restricted?") }

  it { expect(subject.id).to eq(node.model_id) }
  it { expect(subject.labels).to eq([ "#{ node.class.mapped_label_name }" ]) }
  it { expect(subject.node.model_id).to eq(node.model_id) }
  it {
    expect(subject.properties).not_to be_nil
    expect(subject.properties).to eq(object)
  }

  it {
    expect(subject.is_restricted?).to be false
    subject.restricted = true
    expect(subject.is_restricted?).to be true
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
