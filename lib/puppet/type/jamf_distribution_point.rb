require 'puppet/property/boolean'
require 'puppet/util/checksums'

Puppet::Type.newtype(:jamf_distribution_point) do
  desc "Manages a JAMF server's file share distribution points"

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

  newproperty(:ip_address) do
    desc 'Hostname or IP address of the distribution point server.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Hostname/IP Address is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:is_master, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to use as the authoritative source for all files.'

    defaultto false
  end

  newproperty(:connection_type) do
    desc 'Protocol of the file server.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Connection Type is expected to be a String, given: #{value.class.name}"
      end
      allowed_values = ['AFP', 'SMB']
      unless allowed_values.include?(value)
        raise ArgumentError, "Connection Type needs to be one of #{allowed_values}, instead you gave me: #{value['enabled']}"
      end
    end
  end

  newproperty(:share_name) do
    desc 'Name of the share.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Share Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:workgroup_or_domain) do
    desc 'Workgroup or domain of the accounts that have read/write and read-only access to the share.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Share Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:share_port) do
    desc 'Port number of the file server.'

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Share Port is expected to be an Integer, given: #{value.class.name}"
      end
    end
  end

  newproperty(:read_only_username) do
    desc 'Username of account that has read-only access to the share.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Read Only Username is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:read_only_password) do
    desc 'Password of account that has read-only access to the share.'

    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Read Only Password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:read_write_username) do
    desc 'Username of account that has read/write access to the share.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Read Write Username is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:read_write_password) do
    desc 'Password of account that has read/write access to the share.'

    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Read Write Password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:http_downloads_enabled, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to allow downloads over HTTP. HTTP downloads must be enabled on the server for this to work.'

    defaultto false
  end

  newproperty(:http_context) do
    desc "Path to the share (e.g. if the share is accessible at http://192.168.10.10/JamfShare, the context is 'JamfShare')."

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "HTTP Context is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:http_downloads_enabled] == false
        ''
      else
        value
      end
    end
  end

  newproperty(:http_protocol) do
    desc 'HTTP Protocol of the file server.'

    defaultto 'http'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "HTTP Protocol is expected to be a String, given: #{value.class.name}"
      end
      allowed_values = ['http', 'https']
      unless allowed_values.include?(value)
        raise ArgumentError, "HTTP Protocol needs to be one of #{allowed_values}, instead you gave me: #{value['enabled']}"
      end
    end
  end

  newproperty(:http_port) do
    desc 'Port number of the file server.'

    defaultto 80

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "HTTP Port is expected to be an Integer, given: #{value.class.name}"
      end
    end
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

  newproperty(:http_username) do
    desc 'Username of account that has read access to the share.'

    defaultto do
      @resource[:read_only_username]
    end

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "HTTP Username is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:no_authentication_required] == true
        ''
      else
        value
      end
    end
  end

  newparam(:http_password) do
    desc 'Password of account that has read access to the share.'

    sensitive true

    defaultto do
      @resource[:read_only_password]
    end

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "HTTP Password is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:no_authentication_required] == true
        ''
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

  newparam(:dp_name) do
    desc 'Name of the dp for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "dp_name is expected to be a String, given: #{value.class.name}"
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
