require 'rails_helper'

RSpec.describe ApplicationAudit, type: :model do
  it { expect(Audited.audit_class).to eq described_class }
end
