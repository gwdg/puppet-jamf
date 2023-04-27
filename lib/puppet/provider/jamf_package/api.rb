require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_package).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(packages_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    packages_list = body_json['packages']

    # find the category that matches our name
    matches = packages_list.select { |ls| ls['name'] == package_name }
    if matches.size >= 1
      package_id = matches.first['id']
      resp = authorized_http_client.get(packages_url + "/id/#{package_id}",
                                        headers: { 'Accept' => 'application/json' })
      package = JSON.parse(resp.body)['package']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: package['id'],
        name: package['name'],
        category: package['category'],
        filename: package['name'],
        info: package['info'],
        notes: package['notes'],
        priority: package['priority'],
        reboot_required: package['reboot_required'],
        fill_user_template: package['fill_user_template'],
        fill_existing_users: package['fill_existing_users'],
        boot_volume_required: package['boot_volume_required'],
        allow_uninstalled: package['allow_uninstalled'],
        os_requirements: package['os_requirements'],
        install_if_reported_available: package['install_if_reported_available'],
      }
    else
      instance = {
        ensure: :absent,
        name: package_name,
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
        url = packages_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        package: {
          name: package_name,
          category: resource[:category],
          filename: package_name,
          info: resource[:info],
          notes: resource[:notes],
          priority: resource[:priority],
          reboot_required: resource[:reboot_required],
          fill_user_template: resource[:fill_user_template],
          fill_existing_users: resource[:fill_existing_users],
          boot_volume_required: resource[:boot_volume_required],
          allow_uninstalled: resource[:allow_uninstalled],
          os_requirements: resource[:os_requirements],
          install_if_reported_available: resource[:install_if_reported_available],
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(packages_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(packages_url + "/id/#{cached_instance[:id]}",
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

  def packages_url
    # create a URL based on our API URL
    @packages_url ||= "#{resource[:api_url]}/JSSResource/packages"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an package_name attribute for cloud
  #       server management to operate correctly.
  def package_name
    resource[:is_cloud] ? resource[:package_name] : resource[:name]
  end
end
