require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_computer_extension_attribute) do
  desc 'Manages Computer Extension Attributes within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Computer Extension Attribute'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:enabled, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this extension attribute is enabled.'

    isrequired

    defaultto true
  end

  newproperty(:description) do
    desc 'Description of what the Extension Attribute reports on'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "description is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:puppet_warning) do
    desc 'A string automatically added to the end of info to notate that this resource is managed by Puppet.'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Info is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:data_type) do
    desc 'Type of data being collected'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Data Type is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['String', 'Integer', 'Date']
      unless allowed_values.include?(value)
        raise ArgumentError, "Data Type needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:ea_type) do
    desc 'Input type to use to populate the extension attribute'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "EA Type is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['Text Field', 'Pop-up Menu', 'script', 'LDAP Attribute Mapping']
      unless allowed_values.include?(value)
        raise ArgumentError, "EA Type needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:platform) do
    desc 'Which platform this script can run on'

    defaultto 'Mac'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Platform is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:script) do
    desc 'Script to run to populate the Extension Attribute'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Script is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:ea_type] != 'script'
        ''
      else
        value
      end
    end
  end

  newproperty(:script_extension) do
    desc 'What the file type of the script is i.e. sh, py, rb, etc.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Script Extension is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:ea_type] != 'script'
        ''
      else
        value
      end
    end
  end

  newproperty(:inventory_display) do
    desc 'Category in which to display the extension attribute in Jamf Pro'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Inventory Display is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/computerextensionattributes' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:ea_name) do
    desc 'Name of the computer extension attribute for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "ea_name is expected to be a String, given: #{value.class.name}"
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
