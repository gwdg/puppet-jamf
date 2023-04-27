require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_ldap_server).provide(:api, parent: Puppet::Provider::Jamf) do
  # lots of methods inherited from Puppet::Provider::Jamf

  # always need to define this in our implementation classes
  mk_resource_methods

  ##########################
  # private methods that we need to implement because we inherit from Puppet::Provider::Jamf

  # this method should retrieve an instance and return it as a hash
  # note: we explicitly do NOT cache within this method because we want to be
  #       able to call it both in initialize() and in flush() and return the current
  #       state of the resource from the API each time
  def read_instance
    # get a list of all LDAP servers
    resp = authorized_http_client.get(ldapservers_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    ldapservers_list = body_json['ldap_servers']

    # find the LDAP server that matches our name
    matches = ldapservers_list.select { |ls| ls['name'] == ldap_name }
    if matches.size >= 1
      server_id = matches.first['id']
      resp = authorized_http_client.get(ldapservers_url + "/id/#{server_id}",
                                        headers: { 'Accept' => 'application/json' })
      ldapserver = JSON.parse(resp.body)['ldap_server']
      connection = ldapserver['connection']
      mappings_for_users = ldapserver['mappings_for_users']

      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: connection['id'],
        name: connection['name'],
        hostname: connection['hostname'],
        server_type: connection['server_type'],
        port: connection['port'],
        use_ssl: connection['use_ssl'],
        authentication_type: connection['authentication_type'],
        account_dn: connection['account']['distinguished_username'],
        account_password: connection['account']['password_sha256'],
        open_close_timeout: connection['open_close_timeout'],
        search_timeout: connection['search_timeout'],
        referral_response: connection['referral_response'],
        use_wildcards: connection['use_wildcards'],
        user_mappings: mappings_for_users['user_mappings'],
        user_group_mappings: mappings_for_users['user_group_mappings'],
        user_group_membership_mappings: mappings_for_users['user_group_membership_mappings'],
      }
      # TODO
      # if connection.fetch('certificates_used', {}).size > 1
      #   instance[:certificate_used] = connection
      # end
    else
      instance = {
        ensure: :absent,
        name: ldap_name,
      }
    end
    instance
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    case resource[:ensure]
    when :absent
      # don't delete if we can't find an instance that matches by name
      unless cached_instance[:id].nil?
        url = ldapservers_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        ldap_server: {
          connection: {
            name: ldap_name,
            hostname: resource[:hostname],
            server_type: server_type_str(resource[:server_type]),
            port: resource[:port],
            use_ssl: resource[:use_ssl],
            authentication_type: authentication_type_str(resource[:authentication_type]),
            account: {
              distinguished_username: resource[:account_dn],
              password: resource[:account_password],
            },
            open_close_timeout: resource[:open_close_timeout],
            search_timeout: resource[:search_timeout],
            referral_response: referral_response_str(resource[:referral_response]),
            use_wildcards: resource[:use_wildcards],
          },
          mappings_for_users: {
            user_mappings: resource[:user_mappings],
            user_group_mappings: resource[:user_group_mappings],
            user_group_membership_mappings: resource[:user_group_membership_mappings],
          },
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(ldapservers_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(ldapservers_url + "/id/#{cached_instance[:id]}",
                                   body: body,
                                   headers: { 'Content-Type' => 'application/xml' })
      end
    end
  end

  def server_type_str(st)
    case st
    when :active_directory
      'Active Directory'
    when :open_directory
      'Open Directory'
    when :edirectory
      'eDirectory'
    when :custom
      'Custom'
    end
  end

  def authentication_type_str(at)
    case at
    when :simple
      'simple'
    when :cram_md5
      'CRAM-MD5'
    when :digest_md5
      'DIGEST-MD5'
    when :none
      'none'
    end
  end

  def referral_response_str(rr)
    rr
  end

  ################
  # custom methods needed from above
  # NOTE: we must use a cookie in the header of every request made to
  #       cloud servers since they are clustered and we were running
  #       into refresh issues because subsequent calls are dependent upon
  #       earlier ones.
  def authorized_http_client
    @authorized_client ||= Puppet::X::HTTPHelper.new(auth_token: resource[:auth_token],
                                                     is_jamf_cloud: resource[:is_cloud],
                                                     jamf_cookie: resource[:jamf_cookie])
  end

  def ldapservers_url
    # create a URL based on our API URL
    @ldapservers_url ||= "#{resource[:api_url]}/JSSResource/ldapservers"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an ldap_name attribute for cloud
  #       server management to operate correctly.
  def ldap_name
    resource[:is_cloud] ? resource[:ldap_name] : resource[:name]
  end
end
