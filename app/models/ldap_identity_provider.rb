require 'net/ldap'

class LdapIdentityProvider < IdentityProvider
  validates :ldap_base, presence: true

  def affiliate(uid)
    ldap_search(
      Net::LDAP::Filter.construct("uid=#{uid}")
    ).first
  end

  def affiliates(full_name_contains=nil)
    return [] unless full_name_contains && full_name_contains.length > 3
    ldap_search(
      Net::LDAP::Filter.construct("displayName=*#{full_name_contains}*")
    )
  end

  def ldap_search(ldap_filter)
    Net::LDAP.new(
        host: host,
        port: port,
        base: ldap_base
    ).search(
      filter: ldap_filter,
      attributes: %w(uid duDukeID sn givenName mail displayName)
    ).reject {|entry| !entry.attribute_names.include?(:uid)}.map { |entry|
      User.new(
        username: entry.uid.first,
        first_name: entry.givenName.first,
        last_name: entry.sn.first,
        email: entry.mail.first,
        display_name: entry.displayName.first
      )
    }
  end
end
