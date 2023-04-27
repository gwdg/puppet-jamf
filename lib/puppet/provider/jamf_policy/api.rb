require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_policy).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(policy_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    policy_list = body_json['policies']

    # find the category that matches our name
    matches = policy_list.select { |ls| ls['name'] == policy_name }
    if matches.size >= 1
      policy_id = matches.first['id']
      resp = authorized_http_client.get(policy_url + "/id/#{policy_id}",
                                        headers: { 'Accept' => 'application/json' })
      policy_params = JSON.parse(resp.body)['policy']['general']
      policy_datetime = policy_params['date_time_limitations']
      policy_scope = JSON.parse(resp.body)['policy']['scope']
      policy_selfservice = JSON.parse(resp.body)['policy']['self_service']
      policy_packages = JSON.parse(resp.body)['policy']['package_configuration']
      policy_scripts = JSON.parse(resp.body)['policy']['scripts']
      policy_printers = JSON.parse(resp.body)['policy']['printers']
      policy_reboot = JSON.parse(resp.body)['policy']['reboot']
      policy_maintenance = JSON.parse(resp.body)['policy']['maintenance']
      policy_processes = JSON.parse(resp.body)['policy']['files_processes']
      policy_user_interaction = JSON.parse(resp.body)['policy']['user_interaction']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: policy_params['id'],
        name: policy_params['name'],
        enabled: policy_params['enabled'],
        trigger: policy_params['trigger'],
        trigger_checkin: policy_params['trigger_checkin'],
        trigger_enrollment: policy_params['trigger_enrollment_complete'],
        trigger_login: policy_params['trigger_login'],
        trigger_logout: policy_params['trigger_logout'],
        trigger_network_state: policy_params['trigger_network_state_changed'],
        trigger_startup: policy_params['trigger_startup'],
        trigger_other: policy_params['trigger_other'],
        frequency: policy_params['frequency'],
        retry_event: policy_params['retry_event'],
        retry_attempts: policy_params['retry_attempts'],
        notify_on_each_failed_retry: policy_params['notify_on_each_failed_retry'],
        target_drive: policy_params['target_drive'],
        offline: policy_params['offline'],
        category: policy_params['category']['name'],
        activation_date: policy_datetime['activation_date'],
        expiration_date: policy_datetime['expiration_date'],
        no_execute_on: policy_datetime['no_execute_on'],
        no_execute_start: policy_datetime['no_execute_start'],
        no_execute_end: policy_datetime['no_execute_end'],
        all_computers: policy_scope['all_computers'],
        scoped_computers: policy_scope['computers'],
        scoped_computer_groups: policy_scope['computer_groups'],
        scoped_buildings: policy_scope['buildings'],
        scoped_departments: policy_scope['departments'],
        limited_users: policy_scope['limitations']['users'],
        limited_user_groups: policy_scope['limitations']['user_groups'],
        limited_network_segments: policy_scope['limitations']['network_segments'],
        limited_ibeacons: policy_scope['limitations']['ibeacons'],
        excluded_computers: policy_scope['exclusions']['computers'],
        excluded_computer_groups: policy_scope['exclusions']['computer_groups'],
        excluded_buildings: policy_scope['exclusions']['buildings'],
        excluded_departments: policy_scope['exclusions']['departments'],
        excluded_users: policy_scope['exclusions']['users'],
        excluded_user_groups: policy_scope['exclusions']['user_groups'],
        excluded_network_segments: policy_scope['exclusions']['network_segments'],
        excluded_ibeacons: policy_scope['exclusions']['ibeacons'],
        self_service: policy_selfservice['use_for_self_service'],
        self_service_display_name: policy_selfservice['self_service_display_name'],
        install_button_text: policy_selfservice['install_button_text'],
        reinstall_button_text: policy_selfservice['reinstall_button_text'],
        self_service_description: policy_selfservice['self_service_description'],
        force_users_to_view_description: policy_selfservice['force_users_to_view_description'],
        feature_on_main_page: policy_selfservice['feature_on_main_page'],
        self_service_categories: policy_selfservice['self_service_categories'],
        packages: policy_packages['packages'],
        scripts: policy_scripts,
        printers: policy_printers,
        reboot_message: policy_reboot['message'],
        startup_disk: policy_reboot['startup_disk'],
        specify_startup: policy_reboot['specify_startup'],
        no_user_logged_in_action: policy_reboot['no_user_logged_in'],
        user_logged_in_action: policy_reboot['user_logged_in'],
        minutes_until_reboot: policy_reboot['minutes_until_reboot'],
        start_reboot_timer_immediately: policy_reboot['start_reboot_timer_immediately'],
        file_vault_2_reboot: policy_reboot['file_vault_2_reboot'],
        recon: policy_maintenance['recon'],
        reset_name: policy_maintenance['reset_name'],
        install_all_cached_packages: policy_maintenance['install_all_cached_packages'],
        fix_permissions: policy_maintenance['permissions'],
        fix_byhost: policy_maintenance['byhost'],
        flush_system_cache: policy_maintenance['system_cache'],
        flush_user_cache: policy_maintenance['user_cache'],
        verify_startup_disk: policy_maintenance['verify'],
        search_by_path: policy_processes['search_by_path'],
        delete_file: policy_processes['delete_file'],
        locate_file: policy_processes['locate_file'],
        update_locate_database: policy_processes['update_locate_database'],
        spotlight_search: policy_processes['spotlight_search'],
        search_for_process: policy_processes['search_for_process'],
        kill_process: policy_processes['kill_process'],
        run_command: policy_processes['run_command'],
        policy_start_message: policy_user_interaction['message_start'],
        allow_users_to_defer: policy_user_interaction['allow_users_to_defer'],
        allow_deferral_until_utc: policy_user_interaction['allow_deferral_until_utc'],
        allow_deferral_minutes: policy_user_interaction['allow_deferral_minutes'],
        policy_complete_message: policy_user_interaction['message_finish'],
      }
    else
      instance = {
        ensure: :absent,
        name: policy_name,
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
        url = policy_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        policy: {
          general: {
            name: policy_name,
            enabled: resource[:enabled],
            trigger: resource[:trigger],
            trigger_checkin: resource[:trigger_checkin],
            trigger_enrollment_complete: resource[:trigger_enrollment],
            trigger_login: resource[:trigger_login],
            trigger_logout: resource[:trigger_logout],
            trigger_network_state_changed: resource[:trigger_network_state],
            trigger_startup: resource[:trigger_startup],
            trigger_other: resource[:trigger_other],
            frequency: resource[:frequency],
            retry_event: resource[:retry_event],
            retry_attempts: resource[:retry_attempts],
            notify_on_each_failed_retry: resource[:notify_on_each_failed_retry],
            target_drive: resource[:target_drive],
            category: {
              name: resource[:category],
            },
            date_time_limitations: {
              activation_date: resource[:activation_date],
              expiration_date: resource[:expiration_date],
              no_execute_on: resource[:no_execute_on],
              no_execute_start: resource[:no_execute_start],
              no_execute_end: resource[:no_execute_end],
            },
          },
          scope: {
            all_computers: resource[:all_computers],
            computers: {
              computer: resource[:scoped_computers],
            },
            computer_groups: {
              computer_group: resource[:scoped_computer_groups],
            },
            buildings: {
              building: resource[:scoped_buildings],
            },
            departments: {
              department: resource[:scoped_departments],
            },
            limitations: {
              users: {
                user: resource[:limited_users],
              },
              user_groups: {
                user_group: resource[:limited_user_groups],
              },
              network_segments: {
                network_segment: resource[:limited_network_segments],
              },
              ibeacons: {
                ibeacon: resource[:limited_ibeacons],
              },
            },
            exclusions: {
              computers: {
                computer: resource[:excluded_computers],
              },
              computer_groups: {
                computer_group: resource[:excluded_computer_groups],
              },
              buildings: {
                building: resource[:excluded_buildings],
              },
              departments: {
                department: resource[:excluded_departments],
              },
              users: {
                user: resource[:excluded_users],
              },
              user_groups: {
                user_group: resource[:excluded_user_groups],
              },
              network_segments: {
                network_segment: resource[:excluded_network_segments],
              },
              ibeacons: {
                ibeacon: resource[:excluded_ibeacons],
              },
            },
          },
          self_service: {
            use_for_self_service: resource[:self_service],
            self_service_display_name: resource[:self_service_display_name],
            install_button_text: resource[:install_button_text],
            reinstall_button_text: resource[:reinstall_button_text],
            self_service_description: resource[:self_service_description],
            force_users_to_view_description: resource[:force_users_to_view_description],
            feature_on_main_page: resource[:feature_on_main_page],
            self_service_categories: {
              category: resource[:self_service_categories],
            },
          },
          package_configuration: {
            packages: {
              package: resource[:packages],
            },
          },
          scripts: {
            script: resource[:scripts],
          },
          printers: {
            printer: resource[:printers],
          },
          reboot: {
            message: resource[:reboot_message],
            startup_disk: resource[:startup_disk],
            specify_startup: resource[:specify_startup],
            no_user_logged_in: resource[:no_user_logged_in_action],
            user_logged_in: resource[:user_logged_in_action],
            minutes_until_reboot: resource[:minutes_until_reboot],
            start_reboot_timer_immediately: resource[:start_reboot_timer_immediately],
            file_vault_2_reboot: resource[:file_vault_2_reboot],
          },
          maintenance: {
            recon: resource[:recon],
            reset_name: resource[:reset_name],
            install_all_cached_packages: resource[:install_all_cached_packages],
            permissions: resource[:fix_permissions],
            byhost: resource[:fix_byhost],
            system_cache: resource[:flush_system_cache],
            user_cache: resource[:flush_user_cache],
            verify: resource[:verify_startup_disk],
          },
          files_processes: {
            search_by_path: resource[:search_by_path],
            delete_file: resource[:delete_file],
            locate_file: resource[:locate_file],
            update_locate_database: resource[:update_locate_database],
            spotlight_search: resource[:spotlight_search],
            search_for_process: resource[:search_for_process],
            kill_process: resource[:kill_process],
            run_command: resource[:run_command],
          },
          user_interaction: {
            message_start: resource[:policy_start_message],
            allow_users_to_defer: resource[:allow_users_to_defer],
            allow_deferral_until_utc: resource[:allow_deferral_until_utc],
            allow_deferral_minutes: resource[:allow_deferral_minutes],
            message_finish: resource[:policy_complete_message],
          },
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(policy_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(policy_url + "/id/#{cached_instance[:id]}",
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

  def policy_url
    # create a URL based on our API URL
    @policy_url ||= "#{resource[:api_url]}/JSSResource/policies"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an policy_name attribute for cloud
  #       server management to operate correctly.
  def policy_name
    resource[:is_cloud] ? resource[:policy_name] : resource[:name]
  end
end
