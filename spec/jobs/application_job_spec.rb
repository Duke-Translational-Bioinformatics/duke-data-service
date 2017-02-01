require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  let(:child_class) {
    Class.new(described_class) do
      def perform
        true
      end
    end
  }
  it { is_expected.to be_a ActiveJob::Base }
  it { expect{described_class.perform_now}.to raise_error(NotImplementedError) }

  context 'child_class' do
    it { expect{child_class.perform_now}.not_to raise_error }
    it { expect{child_class.perform_later}.not_to raise_error }
  end
end
