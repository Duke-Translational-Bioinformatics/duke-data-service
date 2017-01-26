require 'net/ldap'

class LdapIdentityProvider < IdentityProvider
  validates :ldap_base, presence: true

  def affiliates(auth_provider, full_name_contains=nil)
    users = []
    return users unless full_name_contains && full_name_contains.length > 3
    ldap = Net::LDAP.new(
        host: host,
        port: port,
        base: ldap_base
    )
    filter = Net::LDAP::Filter.construct("displayName=*#{full_name_contains}*")
    entries = ldap.search(
      filter: filter,
      attributes: %w(uid duDukeID sn givenName mail displayName)
    )
    entries.each do |entry|
      if entry.attribute_names.include?(:uid) #we never want anyone without a uid
        user = User.new(
          username: entry.uid.first,
          first_name: entry.givenName.first,
          last_name: entry.sn.first,
          email: entry.mail.first,
          display_name: entry.displayName.first
        )
        user.user_authentication_services.build(
          uid: user.username,
          authentication_service: auth_provider
        )
        users << user
      end
    end
    users
  end
end
