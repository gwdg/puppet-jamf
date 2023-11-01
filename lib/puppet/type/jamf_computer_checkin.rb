require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_computer_checkin) do
  desc "Manages a JAMF server's computer checkin settings"

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc "Name of the organization we're managing."

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:check_in_frequency) do
    desc 'Frequency at which computers check in with Jamf Pro for available policies.'

    isrequired

    defaultto 15

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Check-In Frequency is expected to be an Integer, given: #{value.class.name}"
      end

      allowed_values = [5, 15, 30, 60]
      unless allowed_values.include?(value)
        raise ArgumentError, "Check-In Frequency needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:create_startup_script, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Create a launch daemon that executes on computers at startup.'

    isrequired

    defaultto true
  end

  newproperty(:log_startup_event, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Log the date/time of startup.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:create_startup_script] == false
        false
      else
        value
      end
    end
  end

  newproperty(:check_for_policies_at_startup, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Ensure that computers check for policies triggered by startup.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:create_startup_script] == false
        false
      else
        value
      end
    end
  end

  newproperty(:ensure_ssh_is_enabled, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Enable SSH (Remote Login) on computers that have it disabled.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:create_startup_script] == false
        false
      else
        value
      end
    end
  end

  newproperty(:create_login_logout_hooks, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Create hooks that execute each time a user logs in or logs out. This may disable existing login/logout hooks.'

    isrequired

    defaultto true
  end

  newproperty(:log_username, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Log the username and date/time at login and logout.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:create_login_logout_hooks] == false
        false
      else
        value
      end
    end
  end

  newproperty(:check_for_policies_at_login_logout, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Ensure that computers check for policies triggered by login or logout.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:create_login_logout_hooks] == false
        false
      else
        value
      end
    end
  end

  newproperty(:display_status_to_user, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Display the status of login/logout hook actions. Does not apply to login hook actions performed in the background.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:create_login_logout_hooks] == false
        false
      else
        value
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be 'measured' or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/computercheckin' to the end of this. Default: https://127.0.0.1:8443"

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
