Puppet::Type.newtype(:jamf_conn_validator) do
  desc <<-EOS
    Resource that waits for the JAMF Health Check page to return 200
    https://docs.jamf.com/10.24.1/jamf-pro/administrator-guide/Jamf_Pro_Health_Check_Page.html
  EOS

  ensurable do
    defaultvalues
    defaultto :present
  end

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Arbitrary name used to identify the resource.'
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/healthCheck.html' to the end of this. Default: https://127.0.0.1:8443"

    isrequired

    defaultto 'https://127.0.0.1:8443'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_url is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_username) do
    desc <<-EOS
      Username for authentication to the API. This is not required because the
      healthCheck page, by default, doesn't require authentication
    EOS

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_username is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_password) do
    desc <<-EOS
      Password for authentication to the API. This is not required because the
      healthCheck page, by default, doesn't require authentication
    EOS

    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:timeout) do
    desc 'How long to wait for the API to be available, in seconds'
    defaultto(300)

    validate do |value|
      # This will raise an error if the string is not convertible to an integer
      Integer(value)
    end

    munge do |value|
      Integer(value)
    end
  end
end
