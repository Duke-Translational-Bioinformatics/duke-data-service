class Upload < ActiveRecord::Base
  validates :name, presence: true
end
