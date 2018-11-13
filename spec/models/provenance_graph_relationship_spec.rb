require 'rails_helper'

RSpec.describe ProvenanceGraphRelationship do
  include_context 'mock all Uploads StorageProvider'
  include_context 'performs enqueued jobs', only: GraphPersistenceJob
  # (activity)-(used)->(focus)
  let!(:focus) {
    FactoryBot.create(:file_version, label: "FOCUS")
  }

  let!(:activity) { FactoryBot.create(:activity, name: "ACTIVITY") }
  let!(:activity_used_focus) {
    FactoryBot.create(:used_prov_relation,
      relatable_from: activity,
      relatable_to: focus
    )
  }
  let!(:relationship) { activity_used_focus.graph_relation }
  subject{ ProvenanceGraphRelationship.new(relationship) }

  it { expect(described_class).to include(ActiveModel::Serialization) }
  it { expect(described_class).to include(Comparable) }

  it { is_expected.to respond_to( "id" ) }
  it { is_expected.to respond_to("type") }
  it { is_expected.to respond_to("start_node") }
  it { is_expected.to respond_to("end_node") }
  it { is_expected.to respond_to( "properties" ) }
  it { is_expected.to respond_to( "restricted" ) }
  it { is_expected.to respond_to("restricted=") }
  it { is_expected.to respond_to("is_restricted?") }

  it { expect(subject.id).to eq(activity_used_focus.id) }
  it { expect(subject.type).to eq(relationship.type) }
  it { expect(subject.start_node).to eq(relationship.from_node.model_id) }
  it { expect(subject.end_node).to eq(relationship.to_node.model_id) }
  it {
    expect(subject.properties).not_to be_nil
    expect(subject.properties).to eq(activity_used_focus)
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
        described_class.new(relationship)
      }.not_to raise_error
    }
  end
end
