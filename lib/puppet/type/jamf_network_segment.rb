require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_network_segment) do
  desc 'Manages the network segments available within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Network Segment'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:starting_address) do
    desc "Starting address for the IP range (e.g. '192.168.1.1')"

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "starting_address is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:ending_address) do
    desc "Ending address for the IP range (e.g. '192.168.1.100')"

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "ending_address is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:distribution_point) do
    desc 'Distribution point for computers and mobile devices in the network segment to use by default'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "distribution_point is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:building) do
    desc 'Building to associate with the network segment'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "building is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:department) do
    desc 'Department to associate with the network segment'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "department is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:override_buildings, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to update the building in inventory for computers and mobile devices when they enter the network segment'

    isrequired

    defaultto false
  end

  newproperty(:override_departments, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether or not to update the department in inventory for computers and mobile devices when they enter the network segment'

    defaultto false
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/networksegments' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:segment_name) do
    desc 'Name of the network segment for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "segment_name is expected to be a String, given: #{value.class.name}"
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
