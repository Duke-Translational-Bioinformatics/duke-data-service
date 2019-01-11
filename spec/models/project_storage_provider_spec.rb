require 'rails_helper'

RSpec.describe ProjectStorageProvider, type: :model do
  # Associations
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:storage_provider) }
end
