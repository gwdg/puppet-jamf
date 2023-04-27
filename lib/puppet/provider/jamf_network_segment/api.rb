require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_network_segment).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(network_segments_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    network_segments_list = body_json['network_segments']

    # find the category that matches our name
    matches = network_segments_list.select { |ls| ls['name'] == segment_name }
    if matches.size >= 1
      network_segments_id = matches.first['id']
      resp = authorized_http_client.get(network_segments_url + "/id/#{network_segments_id}",
                                        headers: { 'Accept' => 'application/json' })
      network_segment = JSON.parse(resp.body)['network_segment']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: network_segment['id'],
        name: network_segment['name'],
        starting_address: network_segment['starting_address'],
        ending_address: network_segment['ending_address'],
        distribution_point: network_segment['distribution_point'],
        building: network_segment['building'],
        department: network_segment['department'],
        override_buildings: network_segment['override_buildings'],
        override_departments: network_segment['override_departments'],
      }
    else
      instance = {
        ensure: :absent,
        name: segment_name,
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
        url = network_segments_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        network_segment: {
          name: segment_name,
          starting_address: resource[:starting_address],
          ending_address: resource[:ending_address],
          distribution_point: resource[:distribution_point],
          building: resource[:building],
          department: resource[:department],
          override_buildings: resource[:override_buildings],
          override_departments: resource[:override_departments],
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(network_segments_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(network_segments_url + "/id/#{cached_instance[:id]}",
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

  def network_segments_url
    # create a URL based on our API URL
    @network_segments_url ||= "#{resource[:api_url]}/JSSResource/networksegments"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an segment_name attribute for cloud
  #       server management to operate correctly.
  def segment_name
    resource[:is_cloud] ? resource[:segment_name] : resource[:name]
  end
end
