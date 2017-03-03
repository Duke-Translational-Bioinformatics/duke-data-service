require 'rails_helper'

RSpec.describe MessageLogWorker do
  it { expect(described_class).to include(Sneakers::Worker) }
end
