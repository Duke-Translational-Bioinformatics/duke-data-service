require 'net/ldap'

class LdapIdentityProvider < IdentityProvider
  validates :ldap_base, presence: true

  def affiliates(authentication_service, full_name_contains=nil)
    return [] unless full_name_contains && full_name_contains.length > 3
    Net::LDAP.new(
        host: host,
        port: port,
        base: ldap_base
    ).search(
      filter: Net::LDAP::Filter.construct("displayName=*#{full_name_contains}*"),
      attributes: %w(uid duDukeID sn givenName mail displayName)
    ).reject {|entry| !entry.attribute_names.include?(:uid)}.map { |entry|
      User.new(
        username: entry.uid.first,
        first_name: entry.givenName.first,
        last_name: entry.sn.first,
        email: entry.mail.first,
        display_name: entry.displayName.first,
        user_authentication_services_attributes: [{
          uid: entry.uid.first,
          authentication_service: authentication_service
        }] #http://billpatrianakos.me/blog/2013/09/29/rails-tricky-error-no-implicit-conversion-from-symbol-to-integer/
      )
    }
  end
end
