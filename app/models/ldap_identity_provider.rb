require 'net/ldap'

class LdapIdentityProvider < IdentityProvider
  validates :ldap_base, presence: true

  def affiliate(uid)
    ldap_search(
      Net::LDAP::Filter.construct("uid=#{uid}")
    ).first
  end

  def affiliates(full_name_contains=nil)
    return [] unless full_name_contains && full_name_contains.length >= 3
    ldap_search(
      Net::LDAP::Filter.construct("displayName=*#{full_name_contains}*")
    )
  end

  private

  def ldap_search(ldap_filter)
    ldap = Net::LDAP.new(
        host: host,
        port: port,
        base: ldap_base
    )
    results = []
    success = ldap.search(
      filter: ldap_filter,
      attributes: %w(uid duDukeID sn givenName mail displayName),
      size: 500,
      return_results: false
    ) do |entry|
      if entry.attribute_names.include?(:uid)
        results << User.new(
          username: entry.uid.first,
          first_name: entry.givenName.first,
          last_name: entry.sn.first,
          email: entry.attribute_names.include?(:uid) ? entry.mail.first : nil,
          display_name: entry.displayName.first
        )
      end
    end
    logger.warn "#{ldap.get_operation_result.inspect} results may have been truncated" unless success
    results
  end
end
