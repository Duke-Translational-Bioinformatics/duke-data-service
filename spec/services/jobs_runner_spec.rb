require 'rails_helper'

RSpec.describe JobsRunner do
  subject { described_class.new(initialized_with) }
  let(:initialized_with) { sneakers_worker }
  let(:sneakers_worker) { Class.new { include Sneakers::Worker } }
  let(:mocked_sneakers_runner) { instance_double(Sneakers::Runner) }

  describe '#run' do
    it { is_expected.to respond_to(:run) }

    it 'runs the job with Sneakers::Runner' do
      expect(Sneakers::Runner).to receive(:new)
        .with([sneakers_worker])
        .and_return(mocked_sneakers_runner)
      expect(mocked_sneakers_runner).to receive(:run).and_return(true)
      expect{subject.run}.not_to raise_error
    end

    context 'when initialized with an Array' do
      let(:another_sneakers_worker) { Class.new { include Sneakers::Worker } }
      let(:initialized_with) { [sneakers_worker, another_sneakers_worker] }

      it 'runs both jobs with Sneakers::Runner' do
        expect(Sneakers::Runner).to receive(:new)
          .with([sneakers_worker, another_sneakers_worker])
          .and_return(mocked_sneakers_runner)
        expect(mocked_sneakers_runner).to receive(:run).and_return(true)
        expect{subject.run}.not_to raise_error
      end
    end
  end
end
