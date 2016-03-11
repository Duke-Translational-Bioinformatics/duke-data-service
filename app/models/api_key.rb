class ApiKey < ActiveRecord::Base
  audited

  belongs_to :user
  belongs_to :software_agent
  validates :key, presence: true
end
