require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_activation).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(activation_url,
                                      headers: { 'Accept' => 'application/json' })
    data = JSON.parse(resp.body)
    instance = {
      ensure: :present,
      name: data['activation_code']['organization_name'],
      activation_code: data['activation_code']['code'],
    }
    instance
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
    # create
    hash = {
      activation_code: {
        organization: resource[:name],
        code: resource[:activation_code],
      },
    }
    body = hash_to_xml(hash)
    authorized_http_client.put(activation_url,
                               body: body,
                               headers: { 'Content-Type' => 'application/xml' })
  end

  ################
  # custom methods needed from above
  # NOTE: we must use a cookie in the header of every request made to
  #       cloud servers since they are clustered and we were running
  #       into refresh issues because subsequent calls are dependent upon
  #       earlier ones.
  def authorized_http_client
    @authorized_client ||= Puppet::X::HTTPHelper.new(auth_token: resource[:auth_token],
                                                     is_jamf_cloud: resource[:is_cloud],
                                                     jamf_cookie: resource[:jamf_cookie])
  end

  def activation_url
    # create a URL based on our API URL
    @activation_url ||= "#{resource[:api_url]}/JSSResource/activationcode"
  end
end
