require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_computer_checkin).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(computer_checkin_url,
                                      headers: { 'Accept' => 'application/json' })
    data = JSON.parse(resp.body)
    checkin = data['computer_check_in']
    {
      ensure: :present,
      check_in_frequency: checkin['check_in_frequency'],
      create_startup_script: checkin['create_startup_script'],
      log_startup_event: checkin['log_startup_event'],
      check_for_policies_at_startup: checkin['check_for_policies_at_startup'],
      apply_computer_level_managed_preferences: checkin['apply_computer_level_managed_preferences'],
      ensure_ssh_is_enabled: checkin['ensure_ssh_is_enabled'],
      create_login_logout_hooks: checkin['create_login_logout_hooks'],
      log_username: checkin['log_username'],
      check_for_policies_at_login_logout: checkin['check_for_policies_at_login_logout'],
      apply_user_level_managed_preferences: checkin['apply_user_level_managed_preferences'],
      hide_restore_partition: checkin['hide_restore_partition'],
      perform_login_actions_in_background: checkin['perform_login_actions_in_background'],
      display_status_to_user: checkin['display_status_to_user'],
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
      computer_check_in: {
        check_in_frequency: resource[:check_in_frequency],
        create_startup_script: resource[:create_startup_script],
        log_startup_event: resource[:log_startup_event],
        check_for_policies_at_startup: resource[:check_for_policies_at_startup],
        apply_computer_level_managed_preferences: resource[:apply_computer_level_managed_preferences],
        ensure_ssh_is_enabled: resource[:ensure_ssh_is_enabled],
        create_login_logout_hooks: resource[:create_login_logout_hooks],
        log_username: resource[:log_username],
        check_for_policies_at_login_logout: resource[:check_for_policies_at_login_logout],
        apply_user_level_managed_preferences: resource[:apply_user_level_managed_preferences],
        hide_restore_partition: resource[:hide_restore_partition],
        perform_login_actions_in_background: resource[:perform_login_actions_in_background],
        display_status_to_user: resource[:display_status_to_user],
      },
    }
    body = hash_to_xml(hash)
    authorized_http_client.put(computer_checkin_url,
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

  def computer_checkin_url
    # create a URL based on our API URL
    @computer_checkin_url ||= "#{resource[:api_url]}/JSSResource/computercheckin"
  end
end
