require 'net/ldap'

class LdapIdentityProvider < IdentityProvider
  validates :ldap_base, presence: true

  def affiliate(uid)
    ldap_search(
      filter: {username: uid}
    ).first
  end

  def affiliates(full_name_contains=nil)
    return [] unless full_name_contains && full_name_contains.length >= 3
    ldap_search(
      filter: {full_name_contains: full_name_contains}
    )
  end

  def ldap_filter(filter_hash)
    filter_str = nil
    if val = filter_hash[:username]
      filter_str = "uid=#{val}"
    elsif val = filter_hash[:full_name_contains]
      filter_str = "displayName=*#{val}*"
    end
    Net::LDAP::Filter.construct(filter_str) if filter_str
  end

  def ldap_search(filter:)
    results = []
    success = ldap.search(
      filter: ldap_filter(filter),
      attributes: %w(uid duDukeID sn givenName mail displayName),
      size: 500,
      return_results: false
    ) do |entry|
      if entry.attribute_names.include?(:uid)
        results << User.new(
          username: entry.uid.first,
          first_name: entry.givenName.first,
          last_name: entry.sn.first,
          email: entry.attribute_names.include?(:mail) ? entry.mail.first : nil,
          display_name: entry.displayName.first
        )
      end
    end
    logger.warn "#{ldap.get_operation_result.inspect} results may have been truncated" unless success
    results
  end

  private

  def ldap
    @ldap ||= Net::LDAP.new(
        host: host,
        port: port,
        base: ldap_base
    )
  end
end
