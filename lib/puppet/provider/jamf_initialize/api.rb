require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_initialize).provide(:api, parent: Puppet::Provider::Jamf) do
  # lots of methods inherited from Puppet::Provider::Jamf

  # always need to define this in our implementation classes
  mk_resource_methods

  ##########################
  # private methods that we need to implement because we inherit from Puppet::Provider::Jamf

  # this method should retrieve an instance and return it as a hash
  # note: we explicitly do NOT cache within this method because we want to be
  #       able to call it both in initialize() and in flush() and return the current
  #       state of the resource from the API each time
  def read_instance
    resp = http_client.get(healthcheck_url)
    # response returned 200, as it's supposed to according to the spec
    data = JSON.parse(resp.body)
    instance = {
      ensure: :unknown,
      name: resource[:name],
    }
    if data.size >= 1
      # https://docs.jamf.com/10.24.1/jamf-pro/administrator-guide/Jamf_Pro_Health_Check_Page.html
      if data[0]['healthCode'] == 2 # rubocop:disable Style/GuardClause
        # needs initialized, so mark it as currently being absent
        instance[:ensure] = :absent
      else
        raise "Initialization returned an error: #{data.to_json}"
      end
    else
      # already initialized, so mark it as currently being present
      instance[:ensure] = :present
    end
    instance
  rescue Net::HTTPServiceUnavailable, Net::HTTPFatalError => e
    raise e unless e.response.code == '503'
    # sometimes it returns a 503, so then we're either at SetupAssistant (healthcode = 2)
    # or there is an initialization problem
    data = JSON.parse(resp.body)
    # are we at SetupAssistant (healthcode = 2)?
    if data.size >= 1 && data[0]['healthCode'] == 2 # rubocop:disable Style/GuardClause
      # needs initialized, so mark it as currently being absent
      { ensure: :absent, name: resource[:name] }
    else
      raise e
    end
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    return unless resource[:ensure] == :present
    # perform the initialization
    body = {
      'activationCode' => resource[:activation_code],
      'institutionName' => resource[:name],
      'isEulaAccepted' => true,
      'username' => resource[:api_username],
      'password' => resource[:api_password],
      'email' => resource[:email],
      'jssUrl' => resource[:api_url],
    }
    http_client.post(initialize_url,
                     body: body,
                     headers: { 'Content-Type' => 'application/json',
                                'Accept' => 'application/json' })
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

  def healthcheck_url
    # create an URL based on our API URL
    @healthcheck_url ||= "#{resource[:api_url]}/healthCheck.html"
  end

  def initialize_url
    # create an URL based on our API URL
    @initialize_url ||= "#{resource[:api_url]}/api/system/initialize"
  end
end
