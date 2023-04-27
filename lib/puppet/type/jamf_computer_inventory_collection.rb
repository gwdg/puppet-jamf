require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_computer_inventory_collection) do
  desc "Manages a JAMF server's computer inventory collection settings"

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the organization.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:local_user_accounts, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect UIDs, usernames, full names, and home directory paths for local user accounts.'

    isrequired

    defaultto true
  end

  newproperty(:home_directory_sizes, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Include home directory sizes.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:local_user_accounts] == false
        false
      else
        value
      end
    end
  end

  newproperty(:hidden_accounts, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Include hidden accounts.'

    isrequired

    defaultto true

    munge do |value|
      if @resource[:local_user_accounts] == false
        false
      else
        value
      end
    end
  end

  newproperty(:printers, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect names, models, URIs, and locations of mapped printers.'

    isrequired

    defaultto true
  end

  newproperty(:active_services, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect a list of services running on computers.'

    isrequired

    defaultto true
  end

  newproperty(:mobile_device_app_purchasing_info, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect last backup date/time for managed mobile devices that are synced to computers.'

    isrequired

    defaultto false
  end

  newproperty(:computer_location_information, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect user and location information from the LDAP server when inventory is updated.'

    isrequired

    defaultto true
  end

  newproperty(:package_receipts, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect a list of packages installed or cached using Jamf Pro, or installed by Installer.app or Software Update.'

    isrequired

    defaultto true
  end

  newproperty(:available_software_updates, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Collect a list of available software updates.'

    isrequired

    defaultto false
  end

  newproperty(:include_applications, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Should Application information be collected from computers.'

    isrequired

    defaultto true
  end

  newproperty(:include_fonts, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Should Fonts information be collected from computers.'

    isrequired

    defaultto false
  end

  newproperty(:include_plugins, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Should Plug-ins information be collected from computers.'

    isrequired

    defaultto false
  end

  newproperty(:allow_changing_user_and_location, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Allow local administrators to use the jamf binary recon verb to change User and Location inventory information in Jamf Pro.'

    isrequired

    defaultto true
  end

  newproperty(:custom_search_applications, array_matching: :all) do
    desc 'A list of Custom Search Paths for Applications.'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Custom Search Paths are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('path')
        raise ArgumentError, "Custom Search Paths required to have a 'path' key, given: #{value}"
      end
      unless value['path'].is_a?(String)
        raise ArgumentError, "Custom Search Paths 'path' value expected to be String, given: #{value['path'].class.name}"
      end

      unless value.key?('platform')
        raise ArgumentError, "Custom Search Paths required to have a 'platform' key, given: #{value}"
      end
      unless value['platform'].is_a?(String)
        raise ArgumentError, "Custom Search Paths 'platform' value expected to be String, given: #{value['platform'].class.name}"
      end
    end

    def sort_applications(a)
      if a.nil?
        []
      else
        a.sort_by { |i| i['path'] }
      end
    end

    def should
      sort_applications(super)
    end

    def should=(values)
      super(sort_applications(values))
    end

    def insync?(is)
      sort_applications(is) == should
    end
  end

  newproperty(:custom_search_fonts, array_matching: :all) do
    desc 'A list of Custom Search Paths for Fonts.'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Custom Search Paths are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('path')
        raise ArgumentError, "Custom Search Paths required to have a 'path' key, given: #{value}"
      end
      unless value['path'].is_a?(String)
        raise ArgumentError, "Custom Search Paths 'paths' value expected to be String, given: #{value['path'].class.name}"
      end

      unless value.key?('platform')
        raise ArgumentError, "Custom Search Paths required to have a 'platform' key, given: #{value}"
      end
      unless value['platform'].is_a?(String)
        raise ArgumentError, "Custom Search Paths 'platform' value expected to be String, given: #{value['platform'].class.name}"
      end
    end

    def sort_applications(a)
      if a.nil?
        []
      else
        a.sort_by { |i| i['path'] }
      end
    end

    def should
      sort_applications(super)
    end

    def should=(values)
      super(sort_applications(values))
    end

    def insync?(is)
      sort_applications(is) == should
    end
  end

  newproperty(:custom_search_plugins, array_matching: :all) do
    desc 'A list of Custom Search Paths for Plug-ins.'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Custom Search Paths are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('path')
        raise ArgumentError, "Custom Search Paths required to have a 'paths' key, given: #{value}"
      end
      unless value['path'].is_a?(String)
        raise ArgumentError, "Custom Search Paths 'paths' value expected to be String, given: #{value['path'].class.name}"
      end

      unless value.key?('platform')
        raise ArgumentError, "Custom Search Paths required to have a 'platform' key, given: #{value}"
      end
      unless value['platform'].is_a?(String)
        raise ArgumentError, "Custom Search Paths 'platform' value expected to be String, given: #{value['platform'].class.name}"
      end
    end

    def sort_applications(a)
      if a.nil?
        []
      else
        a.sort_by { |i| i['path'] }
      end
    end

    def should
      sort_applications(super)
    end

    def should=(values)
      super(sort_applications(values))
    end

    def insync?(is)
      sort_applications(is) == should
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be 'measured' or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/computerinventorycollection' to the end of this. Default: https://127.0.0.1:8443"

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
