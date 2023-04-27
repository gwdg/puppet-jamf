require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_distribution_point).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(distribution_points_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    dp_list = body_json['distribution_points']

    # find the category that matches our name
    matches = dp_list.select { |ls| ls['name'] == dp_name }
    if matches.size >= 1
      dp_id = matches.first['id']
      resp = authorized_http_client.get(distribution_points_url + "/id/#{dp_id}",
                                        headers: { 'Accept' => 'application/json' })
      dp = JSON.parse(resp.body)['distribution_point']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: dp['id'],
        name: dp['name'],
        ip_address: dp['ip_address'],
        is_master: dp['is_master'],
        connection_type: dp['connection_type'],
        share_name: dp['share_name'],
        workgroup_or_domain: dp['workgroup_or_domain'],
        share_port: dp['share_port'],
        read_only_username: dp['read_only_username'],
        read_only_password: dp['read_only_password_sha256'],
        read_write_username: dp['read_write_username'],
        read_write_password: dp['read_write_password_sha256'],
        http_downloads_enabled: dp['http_downloads_enabled'],
        http_context: dp['context'],
        http_protocol: dp['protocol'],
        http_port: dp['port'],
        no_authentication_required: dp['no_authentication_required'],
        username_password_required: dp['username_password_required'],
        http_username: dp['http_username'],
        http_password: dp['http_password_sha256'],
      }
    else
      instance = {
        ensure: :absent,
        name: dp_name,
      }
    end
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
    case resource[:ensure]
    when :absent
      # don't delete if we can't find an instance that matches by name
      unless cached_instance[:id].nil?
        url = distribution_points_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        distribution_point: {
          name: dp_name,
          ip_address: resource[:ip_address],
          is_master: resource[:is_master],
          connection_type: resource[:connection_type],
          share_name: resource[:share_name],
          workgroup_or_domain: resource[:workgroup_or_domain],
          share_port: resource[:share_port],
          read_only_username: resource[:read_only_username],
          read_only_password: resource[:read_only_password],
          read_write_username: resource[:read_write_username],
          read_write_password: resource[:read_write_password],
          http_downloads_enabled: resource[:http_downloads_enabled],
          context: resource[:http_context],
          protocol: resource[:http_protocol],
          port: resource[:http_port],
          no_authentication_required: resource[:no_authentication_required],
          username_password_required: resource[:username_password_required],
          http_username: resource[:http_username],
          http_password: resource[:http_password],
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(distribution_points_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(distribution_points_url + "/id/#{cached_instance[:id]}",
                                   body: body,
                                   headers: { 'Content-Type' => 'application/xml' })
      end
    end
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

  def distribution_points_url
    # create a URL based on our API URL
    @distribution_points_url ||= "#{resource[:api_url]}/JSSResource/distributionpoints"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an dp_name attribute for cloud
  #       server management to operate correctly.
  def dp_name
    resource[:is_cloud] ? resource[:dp_name] : resource[:name]
  end
end
