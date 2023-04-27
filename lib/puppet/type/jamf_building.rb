Puppet::Type.newtype(:jamf_building) do
  desc 'Manages the buildings available within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Building'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:streetaddress1) do
    desc 'First line of the Street Address of the building'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Street Address 1 is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:streetaddress2) do
    desc 'Second line of the Street Address of the building'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Street Address 2 is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:city) do
    desc 'The city the building is located in'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "City is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:stateprovince) do
    desc 'The state and/or province the building is located in'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "State/Province is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:zippostalcode) do
    desc 'The zip/postal code the building is located in'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Zip/Postal Code is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:country) do
    desc 'The country the building is located in'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Country is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/api/v1/buildings' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:building_name) do
    desc 'Name of the building for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "building_name is expected to be a String, given: #{value.class.name}"
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
