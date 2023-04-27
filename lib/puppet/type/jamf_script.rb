Puppet::Type.newtype(:jamf_script) do
  desc 'Manages Scripts within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Script'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:category) do
    desc 'Category to add the script to - Must already exist in the Jamf Pro server'

    defaultto 'None'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Category is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:info) do
    desc 'Information to display to the administrator when the script is run'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Info is expected to be a String, given: #{value.class.name}"
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

  newproperty(:notes) do
    desc 'Notes to display about the script (e.g., who created it and when it was created)'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Notes are expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:priority) do
    desc 'Priority to use for running the script in relation to other actions during imaging'

    defaultto 'After'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Priority is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['After', 'Before', 'At Reboot']
      unless allowed_values.include?(value)
        raise ArgumentError, "Priority needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:parameter4) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 4 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter5) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 5 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter6) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 6 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter7) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 7 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter8) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 8 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter9) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 9 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter10) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 10 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:parameter11) do
    desc 'Labels to use for script parameters. Parameters 1 through 3 are predefined as mount point, computer name, and username'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Parameter 11 is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value == ''
        :absent
      else
        value
      end
    end
  end

  newproperty(:os_requirements) do
    desc "The script can only be run on computers with these operating system versions. Each version must be separated by a comma (e.g., '10.6.8, 10.7.x, 10.8')"

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "OS Requirements are expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:script) do
    desc 'The full script contents'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Script is expected to be a String, given: #{value.class.name}"
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
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/scripts' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:script_name) do
    desc 'Name of the script for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "script_name is expected to be a String, given: #{value.class.name}"
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
