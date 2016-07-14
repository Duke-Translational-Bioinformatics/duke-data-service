class ApiKey < ActiveRecord::Base
  include RequestAudited
  audited

  belongs_to :user
  belongs_to :software_agent
  validates :key, presence: true
end
