require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_package) do
  desc 'Manages the packages available within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Package'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:category) do
    desc 'Category to add the package to'

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "category is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:info) do
    desc 'Information to display to the administrator when the package is deployed or uninstalled'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "info is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:notes) do
    desc 'Notes to display about the package (e.g. who built it and when it was built)'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "notes is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:priority) do
    desc "Priority to use for deploying or uninstalling the package (e.g. A package with a priority of '1' is deployed or uninstalled before other packages)"

    defaultto 10

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "priority is expected to be an Integer, given: #{value.class.name}"
      end
    end
  end

  newproperty(:reboot_required, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not computers must be restarted after installing the package'

    defaultto false
  end

  newproperty(:fill_user_template, boolean: true, parent: Puppet::Property::Boolean) do
    desc "Whether or not to fill new home directories with the contents of the home directory in the package's Users folder." \
         'Applies to DMGs only. This setting can be changed when deploying or uninstalling the package using a policy'

    defaultto false
  end

  newproperty(:fill_existing_users, boolean: true, parent: Puppet::Property::Boolean) do
    desc "Whether or not to fill existing home directories with the contents of the home directory in the package's Users folder." \
         'Applies to DMGs only. This setting can be changed when deploying or uninstalling the package using a policy'

    defaultto false
  end

  newproperty(:boot_volume_required, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to ensure that the package is installed on the boot drive after imaging'

    defaultto false
  end

  newproperty(:allow_uninstalled, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to allow the package to be uninstalled using Jamf Remote or a policy. Applies to indexed packages only. Packages can only be indexed using Jamf Admin.'

    defaultto false
  end

  newproperty(:os_requirements) do
    desc "The package can only be deployed to computers with these operating system versions. Each version must be separated by a comma (e.g. '10.6.8, 10.7.x, 10.8')"

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "os_requirements is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:install_if_reported_available, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to install the package only if it is available as an update.' \
         'For this to work, the display name of the package must match the name in the command-line version of Software Update. Applies to PKGs only'

    defaultto false
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/packages' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:package_name) do
    desc 'Name of the package for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "package_name is expected to be a String, given: #{value.class.name}"
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
