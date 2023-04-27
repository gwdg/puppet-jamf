require 'puppet/property/boolean'
require 'puppet/util/checksums'

Puppet::Type.newtype(:jamf_distribution_point_failover) do
  desc "Manages a JAMF server's file share distribution point failover configuration"

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Display name for the distribution point.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:failover_point) do
    desc 'Distribution point to use if the specified server is not available.'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Failover Point is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:enable_load_balancing, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to randomly distribute the load between this distribution point and the failover distribution point.'

    defaultto false
  end

  newproperty(:no_authentication_required, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not authentication is required to download files from the distribution point.'

    defaultto true
  end

  newproperty(:username_password_required, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not authentication is required to download files from the distribution point.'

    defaultto false

    munge do |value|
      if @resource[:no_authentication_required] == true
        false
      else
        value
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be 'measured' or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/accounts' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:dpf_name) do
    desc 'Name of the distribution point failover for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "dpf_name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:is_cloud, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Check is server is cloud or internal'

    isrequired

    defaultto false
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

  newparam(:conn_validator) do
    desc 'Title of the jamf_conn_validator resource to auto-require'

    defaultto 'jamf'
  end

  autorequire(:jamf_conn_validator) do
    @parameters[:conn_validator]
  end
end
