require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_conn_validator).provide(:api) do
  ##########################
  # private methods that we need to implement because we inherit from Puppet::Provider::Jamf
  def exists?
    start_time = Time.now
    timeout = resource[:timeout]

    success = attempt_connection

    while success == false && ((Time.now - start_time) < timeout)
      # It can take several seconds for the JAMF server to start up;
      # especially on the first install.  Therefore, our first connection attempt
      # may fail.  Here we have somewhat arbitrarily chosen to retry every 2
      # seconds until the configurable timeout has expired.
      Puppet.notice('Failed to connect to JAMF API; sleeping 5 seconds before retry')
      sleep 5
      success = attempt_connection
    end

    unless success
      Puppet.notice("Failed to connect to JAMF within timeout window of #{timeout} seconds; giving up.")
    end

    success
  end

  # This method is called when the exists? method returns false.
  #
  # @return [void]
  def create
    # If `#create` is called, that means that `#exists?` returned false, which
    # means that the connection could not be established... so we need to
    # cause a failure here.
    raise Puppet::Error, "Unable to connect to Jamf server! (#{@validator.health_check_url})"
  end

  ################
  # custom methods needed from above
  def http_client
    # create an HTTP client with this username/password and cache it
    # be sure to use resource[:xxx] here so that we can use the parameters
    # set by the user in the DSL declaration of this resource
    @client ||= Puppet::X::HTTPHelper.new(username: resource[:api_username],
                                          password: resource[:api_password])
  end

  def health_check_url
    # create an URL based on our API URL
    @health_check_url ||= "#{resource[:api_url]}/healthCheck.html"
  end

  def attempt_connection
    is_connected = true

    response = http_client.get(health_check_url)
    unless response.is_a?(Net::HTTPSuccess)
      Puppet.notice "Unable to connect to JAMF server (#{health_check_url}): [#{response.code}] #{response.msg}"
      is_connected = false
    end
    is_connected
  rescue Exception => e # rubocop:disable Lint/RescueException
    Puppet.notice "Unable to connect to JAMF server (#{health_check_url}): #{e.message}"
    is_connected
  end
end
