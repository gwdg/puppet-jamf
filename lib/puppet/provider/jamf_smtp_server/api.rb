require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_smtp_server).provide(:api, parent: Puppet::Provider::Jamf) do
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
    # Get the current SMTP server settings
    resp = authorized_http_client.get(smtpserver_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    smtpserver = body_json['smtp_server']
    {
      ensure: :present,
      enabled: smtpserver['enabled'],
      host: smtpserver['host'],
      port: smtpserver['port'],
      timeout: smtpserver['timeout'],
      authorization_required: smtpserver['authorization_required'],
      username: smtpserver['username'],
      password: smtpserver['password'],
      ssl: smtpserver['ssl'],
      tls: smtpserver['tls'],
      encryption: smtpserver['encryption'],
      send_from_name: smtpserver['send_from_name'],
      send_from_email: smtpserver['send_from_email'],
    }
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
      smtp_server: {
        enabled: resource[:enabled],
        host: resource[:host],
        port: resource[:port],
        timeout: resource[:timeout],
        authorization_required: resource[:authorization_required],
        username: resource[:username],
        password: resource[:password],
        ssl: resource[:ssl],
        tls: resource[:tls],
        encryption: resource[:encryption],
        send_from_name: resource[:send_from_name],
        send_from_email: resource[:send_from_email],
      },
    }
    body = hash_to_xml(hash)
    authorized_http_client.put(smtpserver_url,
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

  def smtpserver_url
    # create a URL based on our API URL
    @smtpserver_url ||= "#{resource[:api_url]}/JSSResource/smtpserver"
  end
end
