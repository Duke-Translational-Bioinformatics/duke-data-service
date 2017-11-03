require 'rails_helper'

RSpec.describe GraphPersistenceJob, type: :job do
  let(:prefix) { Rails.application.config.active_job.queue_name_prefix }
  let(:prefix_delimiter) { Rails.application.config.active_job.queue_name_delimiter }
  it { is_expected.to be_an ApplicationJob }
  it { expect(prefix).not_to be_nil }
  it { expect(prefix_delimiter).not_to be_nil }
  it { expect(described_class.queue_name).to eq("#{prefix}#{prefix_delimiter}graph_persistence") }

  it {
    expect{described_class.perform_now}.to raise_error(ArgumentError)
  }

  let(:agent) { FactoryGirl.create(:user) }
  let(:graphed_class) { agent.graph_model_class }
  let(:job_transaction) { described_class.initialize_job(agent) }

  context 'action is "create"' do
    include_context 'tracking job', :job_transaction
    let(:create_params) { {foo: 'bar'} }
    it 'calls .create on graphed_class' do
      expect(graphed_class).to receive(:create).with(create_params).and_return(true)
      described_class.perform_now(job_transaction, graphed_class.name, action: "create", params: create_params)
    end
  end

  context 'action is "save"' do
  end

  context 'action is "delete"' do
    include_context 'tracking job', :job_transaction
    let(:graphed_model_object) { double('graph_model') }
    let(:delete_params) { {foo: 'bar'} }
    it 'calls .delete on graphed_class' do
      expect(graphed_class).to receive(:find_by).with(delete_params).and_return(graphed_model_object)
      expect(graphed_model_object).to receive(:destroy).and_return(true)
      described_class.perform_now(job_transaction, graphed_class.name, action: "delete", params: delete_params)
    end
  end
end
