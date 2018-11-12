require 'net/ldap'

class LdapIdentityProvider < IdentityProvider
  validates :ldap_base, presence: true

  def affiliate(uid)
    ldap_search(
      filter: {username: uid}
    ).first
  end

  def affiliates(full_name_contains: nil, username: nil, email: nil)
    filter = {}
    if username
      filter[:username] = username
    elsif email
      filter[:email] = email
    elsif full_name_contains && full_name_contains.length >= 3
      filter[:full_name_contains] = full_name_contains
    else
      return []
    end
    ldap_search(filter: filter)
  end

  def ldap_filter(filter_hash)
    filter_attr = nil
    if val = filter_hash[:username]
      filter_attr = "uid"
    elsif val = filter_hash[:email]
      filter_attr = "mail"
    elsif val = filter_hash[:full_name_contains]
      filter_attr = "displayName"
      val = "*#{val}*"
    end
    Net::LDAP::Filter.eq(filter_attr, val) if filter_attr
  end

  def valid_ldap_entry?(entry)
    entry.attribute_names.include?(:uid)
  end

  def ldap_entry_to_user(entry)
    if entry.attribute_names.include?(:uid)
      User.new(
        username: entry[:uid].first,
        first_name: entry[:givenName].first,
        last_name: entry[:sn].first,
        email: entry[:mail].first,
        display_name: entry[:displayName].first
      )
    end
  end

  def ldap_search(filter:)
    results = []
    success = ldap_conn.search(
      filter: ldap_filter(filter),
      attributes: %w(uid duDukeID sn givenName mail displayName),
      size: 500,
      return_results: false
    ) do |entry|
      if new_user = ldap_entry_to_user(entry)
        results << new_user
      end
    end
    logger.warn "#{ldap_conn.get_operation_result.inspect} results may have been truncated" unless success
    results
  end

  def ldap_conn
    @ldap_conn ||= Net::LDAP.new(
        host: host,
        port: port,
        base: ldap_base
    )
  end
end
