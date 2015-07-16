module StringIdCreator
  extend ActiveSupport::Concern

  def create_string_id
    self.id ||= SecureRandom.uuid
  end

end
