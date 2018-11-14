class IdentityProvider < ActiveRecord::Base
  validates :host, presence: true
  validates :port, presence: true

  attr_accessor :affiliates_offset, :affiliates_limit

  def affiliates(full_name_contains: nil, username: nil, email: nil)
    raise NotImplementedError
  end

  def affiliate(uid)
    raise NotImplementedError
  end
end
