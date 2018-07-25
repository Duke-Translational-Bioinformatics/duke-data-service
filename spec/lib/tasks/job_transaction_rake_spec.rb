require 'rails_helper'

describe 'job_transaction:clean_up' do
  include_context "rake"

  it { expect {invoke_task}.not_to raise_error }
end
