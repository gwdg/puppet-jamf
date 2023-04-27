require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_advanced_mobile_device_search).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(adv_mobile_device_search_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    searches_list = body_json['advanced_mobile_device_searches']

    # find the category that matches our name
    matches = searches_list.select { |ls| ls['name'] == mobile_search_name }
    if matches.size >= 1
      search_id = matches.first['id']
      resp = authorized_http_client.get(adv_mobile_device_search_url + "/id/#{search_id}",
                                        headers: { 'Accept' => 'application/json' })
      search = JSON.parse(resp.body)['advanced_mobile_device_search']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: search['id'],
        name: search['name'],
        criteria: search['criteria'],
      }
    else
      instance = {
        ensure: :absent,
        name: mobile_search_name,
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
        url = adv_mobile_device_search_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        advanced_mobile_device_search: {
          name: mobile_search_name,
          criteria: {
            criterion: resource[:criteria],
          },
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(adv_mobile_device_search_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(adv_mobile_device_search_url + "/id/#{cached_instance[:id]}",
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

  def adv_mobile_device_search_url
    # create a URL based on our API URL
    @adv_mobile_device_search_url ||= "#{resource[:api_url]}/JSSResource/advancedmobiledevicesearches"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an mobile_search_name attribute for cloud
  #       server management to operate correctly.
  def mobile_search_name
    resource[:is_cloud] ? resource[:mobile_search_name] : resource[:name]
  end
end
