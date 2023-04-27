require 'puppet/property/boolean'
require 'puppet/util/checksums'

Puppet::Type.newtype(:jamf_ldap_server) do
  desc 'Manages a JAMF LDAP Server configuration.'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the LDAP server'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:hostname) do
    desc 'Hostname of the LDAP server.'

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "hostname is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:server_type) do
    desc 'Type of LDAP server'
    newvalues(:active_directory, :open_directory, :edirectory, :custom)

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "server_type is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:port) do
    desc 'Port for LDAP server'

    isrequired

    defaultto 636

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "port is expected to be an Integer, given: #{value.class.name}"
      end
    end
  end

  newproperty(:use_ssl, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Should LDAP use SSL or not.'

    isrequired

    defaultto false
  end

  newproperty(:authentication_type) do
    desc 'type of authentication to perform with LDAP'
    newvalues(:simple, :cram_md5, :digest_md5, :none)

    isrequired

    defaultto :simple
  end

  # newproperty(:certificate_used) do
  #   desc 'Supports PEM and based64 encoded DER formats'

  #   validate do |value|
  #     unless value.is_a?(String)
  #       raise ArgumentError, "certificate_used is expected to be an String, given: #{value.class.name}"
  #     end
  #   end
  # end

  newproperty(:account_dn) do
    desc 'Full DN of account to use for binding to LDAP.'

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "account_dn is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:account_password) do
    desc 'Password for LDAP bind account.'
    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "account_password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:open_close_timeout) do
    desc 'Timeout, in seconds, for opening the LDAP connection'

    defaultto 15

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "open_close_timeout is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:search_timeout) do
    desc 'Timeout, in seconds, searching LDAP'

    defaultto 60

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "search_timeout is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:referral_response) do
    desc 'Should referrals be followed or not.'
    newvalues(:ignore, :follow)
  end

  newproperty(:use_wildcards, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Should LDAP use wildcards for searching or not.'

    isrequired

    defaultto true
  end

  newproperty(:user_mappings) do
    desc 'Hash of user mappings, see https://github.com/jamf/Classic-API-Swagger-Specification/blob/master/swagger.yaml'

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, "user_mappings is expected to be a Hash, given: #{value.class.name}"
      end
    end
  end

  newproperty(:user_group_mappings) do
    desc 'Hash of user/group mappings, see https://github.com/jamf/Classic-API-Swagger-Specification/blob/master/swagger.yaml'

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, "user_group_mappings is expected to be a Hash, given: #{value.class.name}"
      end
    end
  end

  newproperty(:user_group_membership_mappings) do
    desc 'Hash of user-group membership mappings, see https://github.com/jamf/Classic-API-Swagger-Specification/blob/master/swagger.yaml'

    validate do |value|
      unless value.is_a?(Hash)
        raise ArgumentError, "user_group_membership_mappings is expected to be a Hash, given: #{value.class.name}"
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/ldapservers' to the end of this. Default: https://127.0.0.1:8443"

    isrequired

    defaultto 'https://127.0.0.1:8443'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_url is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_username) do
    desc 'Username for authentication to the API.'

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_username is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_password) do
    desc 'Password for authentication to the API.'

    isrequired

    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:ldap_name) do
    desc 'Name of the ldap server for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "LDAP Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:is_cloud, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Check is server is cloud or internal'

    isrequired

    defaultto false
  end

  newparam(:conn_validator) do
    desc 'Title of the jamf_conn_validator resource to auto-require'

    defaultto 'jamf'
  end

  newparam(:auth_token) do
    desc 'Token used for authentication to the API.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "auth_token is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:jamf_cookie) do
    desc 'Cookie used to avoid cluster refresh issues with cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "jamf_cookie is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  autorequire(:jamf_conn_validator) do
    @parameters[:conn_validator]
  end
end
