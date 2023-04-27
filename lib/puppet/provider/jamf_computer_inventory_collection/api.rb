require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_computer_inventory_collection).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(computer_inventory_collection_url,
                                      headers: { 'Accept' => 'application/json' })
    data = JSON.parse(resp.body)
    inventory = data['computer_inventory_collection']
    {
      ensure: :present,
      local_user_accounts: inventory['local_user_accounts'],
      home_directory_sizes: inventory['home_directory_sizes'],
      hidden_accounts: inventory['hidden_accounts'],
      printers: inventory['printers'],
      active_services: inventory['active_services'],
      mobile_device_app_purchasing_info: inventory['mobile_device_app_purchasing_info'],
      computer_location_information: inventory['computer_location_information'],
      package_receipts: inventory['package_receipts'],
      available_software_updates: inventory['available_software_updates'],
      include_applications: inventory['include_applications'],
      include_fonts: inventory['include_fonts'],
      include_plugins: inventory['include_plugins'],
      allow_changing_user_and_location: inventory['allow_changing_user_and_location'],
      custom_search_applications: inventory['applications'],
      custom_search_fonts: inventory['fonts'],
      custom_search_plugins: inventory['plugins'],
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
      computer_inventory_collection: {
        local_user_accounts: resource[:local_user_accounts],
        home_directory_sizes: resource[:home_directory_sizes],
        hidden_accounts: resource[:hidden_accounts],
        printers: resource[:printers],
        active_services: resource[:active_services],
        mobile_device_app_purchasing_info: resource[:mobile_device_app_purchasing_info],
        computer_location_information: resource[:computer_location_information],
        package_receipts: resource[:package_receipts],
        available_software_updates: resource[:available_software_updates],
        include_applications: resource[:include_applications],
        include_fonts: resource[:include_fonts],
        include_plugins: resource[:include_plugins],
        allow_changing_user_and_location: resource[:allow_changing_user_and_location],
        applications: {
          application: resource[:custom_search_applications],
        },
        fonts: {
          font: resource[:custom_search_fonts],
        },
        plugins: {
          plugin: resource[:custom_search_plugins],
        },
      },
    }
    body = hash_to_xml(hash)
    authorized_http_client.put(computer_inventory_collection_url,
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

  def computer_inventory_collection_url
    # create a URL based on our API URL
    @computer_inventory_collection_url ||= "#{resource[:api_url]}/JSSResource/computerinventorycollection"
  end
end
