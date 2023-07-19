require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_policy) do
  desc 'Manages Policies within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Policy'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:enabled, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy is active or not'

    defaultto false
  end

  newproperty(:trigger) do
    desc 'Trigger of the policy'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Trigger is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:trigger_checkin, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy should run on check-in'

    defaultto false
  end

  newproperty(:trigger_enrollment, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy should run upon completion of the enrollment process'

    defaultto false
  end

  newproperty(:trigger_login, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy should run on login'

    defaultto false
  end

  newproperty(:trigger_logout, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy should run on logout'

    defaultto false
  end

  newproperty(:trigger_network_state, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy should run on network state change'

    defaultto false
  end

  newproperty(:trigger_startup, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this policy should run on startup'

    defaultto false
  end

  newproperty(:trigger_other) do
    desc 'Custom trigger to allow this policy to be called from elsewhere'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Trigger Other is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:frequency) do
    desc 'How often the policy should run'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Frequency is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['Ongoing', 'Once per computer', 'Once per user per computer', 'Once per user', 'Once every day', 'Once every week', 'Once every month']
      unless allowed_values.include?(value)
        raise ArgumentError, "Frequency needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:retry_event) do
    desc 'Event to use to re-run the policy'

    defaultto 'none'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Retry Event is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['none', 'check-in', 'trigger']
      unless allowed_values.include?(value)
        raise ArgumentError, "Retry Event needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:retry_attempts) do
    desc 'Number of retry events for the policy'

    defaultto { -1 }

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Retry Attempts is expected to be an Integer, given: #{value.class.name}"
      end
    end
  end

  newproperty(:notify_on_each_failed_retry, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to send notifications for each failed policy retry'

    defaultto false
  end

  newproperty(:target_drive) do
    desc 'The drive on which to run the policy (e.g. "/Volumes/Restore/"). The policy runs on the boot drive by default'

    defaultto '/'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Target Drive is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:offline, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to cache the policy to ensure it runs when Jamf Pro is unavailable'

    defaultto false
  end

  newproperty(:category) do
    desc 'Category to add the policy to'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Category is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:activation_date) do
    desc 'Date/time to make the policy active'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Activation Date is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:expiration_date) do
    desc 'Date/time to make the policy expire'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Expiration Date is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:no_execute_on, array_matching: :all) do
    desc 'Days on which the policy should not run'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "No Execute On is expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('day')
        raise ArgumentError, "No Execute On required to have a 'day' key, given: #{value}"
      end
      allowed_values = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
      unless allowed_values.include?(value['day'])
        raise ArgumentError, "No Execute On 'day' key needs to be one of #{allowed_values}, instead you gave me: #{value['day']}"
      end
    end

    def sort_days(a)
      if a.nil?
        []
      else
        allowed_fields = ['day']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['day'] }
      end
    end

    def should
      sort_days(super)
    end

    def should=(values)
      super(sort_days(values))
    end

    def insync?(is)
      sort_days(is) == should
    end
  end

  newproperty(:no_execute_start) do
    desc 'Time range during which the policy should not run'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "No Execute Start is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:no_execute_end) do
    desc 'Time range during which the policy should not run'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "No Execute End is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:all_computers, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to scope the policy to all computers'

    defaultto false
  end

  newproperty(:scoped_computers, array_matching: :all) do
    desc 'Computers to scope the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Computers are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Computers required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Computers 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_computers(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_computers(super)
    end

    def should=(values)
      super(sort_computers(values))
    end

    def insync?(is)
      sort_computers(is) == should
    end
  end

  newproperty(:scoped_computer_groups, array_matching: :all) do
    desc 'Computer Groups to scope the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Computer Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Computer Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Computer Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_groups(super)
    end

    def should=(values)
      super(sort_groups(values))
    end

    def insync?(is)
      sort_groups(is) == should
    end
  end

  newproperty(:scoped_buildings, array_matching: :all) do
    desc 'Buildings to scope the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Buildings are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Buildings required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Buildings 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_buildings(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_buildings(super)
    end

    def should=(values)
      super(sort_buildings(values))
    end

    def insync?(is)
      sort_buildings(is) == should
    end
  end

  newproperty(:scoped_departments, array_matching: :all) do
    desc 'Departments to scope the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Departments are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Departments required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Departments 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_departments(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_departments(super)
    end

    def should=(values)
      super(sort_departments(values))
    end

    def insync?(is)
      sort_departments(is) == should
    end
  end

  newproperty(:limited_users, array_matching: :all) do
    desc 'LDAP/Local Users to limit the scope of the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Limited Users are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Limited Users required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Limited Users 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_users(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_users(super)
    end

    def should=(values)
      super(sort_users(values))
    end

    def insync?(is)
      sort_users(is) == should
    end
  end

  newproperty(:limited_user_groups, array_matching: :all) do
    desc 'LDAP Groups to limit the scope of the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Limited User Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Limited User Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Limited User Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_user_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_user_groups(super)
    end

    def should=(values)
      super(sort_user_groups(values))
    end

    def insync?(is)
      sort_user_groups(is) == should
    end
  end

  newproperty(:limited_network_segments, array_matching: :all) do
    desc 'Network Segments to limit the scope of the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Limited Network Segments are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Limited Network Segments required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Limited Network Segments 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_network_segments(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_network_segments(super)
    end

    def should=(values)
      super(sort_network_segments(values))
    end

    def insync?(is)
      sort_network_segments(is) == should
    end
  end

  newproperty(:limited_ibeacons, array_matching: :all) do
    desc 'iBeacons to limit the scope of the policy to'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Limited iBeacons are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Limited iBeacons required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Limited iBeacons 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_ibeacons(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_ibeacons(super)
    end

    def should=(values)
      super(sort_ibeacons(values))
    end

    def insync?(is)
      sort_ibeacons(is) == should
    end
  end

  newproperty(:excluded_computers, array_matching: :all) do
    desc 'Computers on which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Computers are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Computers required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Computers 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_computers(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_computers(super)
    end

    def should=(values)
      super(sort_computers(values))
    end

    def insync?(is)
      sort_computers(is) == should
    end
  end

  newproperty(:excluded_computer_groups, array_matching: :all) do
    desc 'Computer Groups on which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Computer Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Computer Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Computer Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_groups(super)
    end

    def should=(values)
      super(sort_groups(values))
    end

    def insync?(is)
      sort_groups(is) == should
    end
  end

  newproperty(:excluded_buildings, array_matching: :all) do
    desc 'Buildings on which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Buildings are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Buildings required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Buildings 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_buildings(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_buildings(super)
    end

    def should=(values)
      super(sort_buildings(values))
    end

    def insync?(is)
      sort_buildings(is) == should
    end
  end

  newproperty(:excluded_departments, array_matching: :all) do
    desc 'Departments on which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Departments are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Departments required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Departments 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_departments(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_departments(super)
    end

    def should=(values)
      super(sort_departments(values))
    end

    def insync?(is)
      sort_departments(is) == should
    end
  end

  newproperty(:excluded_users, array_matching: :all) do
    desc 'Users for which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Users are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Users required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Users 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_users(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_users(super)
    end

    def should=(values)
      super(sort_users(values))
    end

    def insync?(is)
      sort_users(is) == should
    end
  end

  newproperty(:excluded_user_groups, array_matching: :all) do
    desc 'User Groups for which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded User Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded User Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded User Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_user_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_user_groups(super)
    end

    def should=(values)
      super(sort_user_groups(values))
    end

    def insync?(is)
      sort_user_groups(is) == should
    end
  end

  newproperty(:excluded_network_segments, array_matching: :all) do
    desc 'Network Segements for which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Network Segments are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Network Segments required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Network Segments 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_network_segments(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_network_segments(super)
    end

    def should=(values)
      super(sort_network_segments(values))
    end

    def insync?(is)
      sort_network_segments(is) == should
    end
  end

  newproperty(:excluded_ibeacons, array_matching: :all) do
    desc 'iBeacons for which to not assign the profile'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded iBeacons are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded iBeacons required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded iBeacons 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_ibeacons(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_ibeacons(super)
    end

    def should=(values)
      super(sort_ibeacons(values))
    end

    def insync?(is)
      sort_ibeacons(is) == should
    end
  end

  newproperty(:self_service, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to make the policy available in Self Service'

    defaultto false
  end

  newproperty(:self_service_display_name) do
    desc 'Display name for the policy in Self Service (Self Service 10.0.0 or later)'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Self Service Display Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:install_button_text) do
    desc 'Name for the button that users click to initiate the policy'

    defaultto 'Install'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Reinstall Button Text is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:reinstall_button_text) do
    desc 'Name for the button that users click to reinitiate the policy'

    defaultto 'Reinstall'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Install Button Text is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:self_service_description) do
    desc 'Description to display for the policy in Self Service'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Self Service Description is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:force_users_to_view_description, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Force users to view the description before the policy runs'

    defaultto false
  end

  newproperty(:feature_on_main_page, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to include the policy in the Featured category'

    defaultto false
  end

  newproperty(:self_service_categories, array_matching: :all) do
    desc 'The categories within Self Service in which to display the policy'

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Self Service Categories are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Self Service Categories required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Self Service Categories 'name' value expected to be String, given: #{value['name'].class.name}"
      end

      unless value.key?('display_in')
        value.store('display_in', true)
      end
      allowed_values = [true, false]
      unless allowed_values.include?(value['display_in'])
        raise ArgumentError, "Self Service Categories 'display_in' key needs to be one of #{allowed_values}, instead you gave me: #{value['display_in']}"
      end

      unless value.key?('feature_in')
        value.store('feature_in', false)
      end
      allowed_values = [true, false]
      unless allowed_values.include?(value['feature_in'])
        raise ArgumentError, "Self Service Categories 'feature_in' key needs to be one of #{allowed_values}, instead you gave me: #{value['feature_in']}"
      end
    end

    def sort_categories(a)
      if a.nil?
        []
      else
        allowed_fields = ['name', 'display_in', 'feature_in']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_categories(super)
    end

    def should=(values)
      super(sort_categories(values))
    end

    def insync?(is)
      sort_categories(is) == should
    end
  end

  newproperty(:packages, array_matching: :all) do
    desc 'Packages to install via the policy'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, 'Packages are expected to be a Hash, given: #{value.class.name}'
      end

      unless value.key?('name')
        raise ArgumentError, "Packages required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Packages 'name' value expected to be String, given: #{value['name'].class.name}"
      end

      unless value.key?('action')
        value.store('action', 'Install')
      end
      allowed_values = ['Install', 'Cache', 'Install Cached']
      unless allowed_values.include?(value['action'])
        raise ArgumentError, "Packages 'action' key needs to be one of #{allowed_values}, instead you gave me: #{value['action']}"
      end

      unless value.key?('fut')
        value.store('fut', false)
      end
      allowed_values = [true, false]
      unless allowed_values.include?(value['fut'])
        raise ArgumentError, "Packages 'fut' key needs to be one of #{allowed_values}, instead you gave me: #{value['fut']}"
      end

      unless value.key?('feu')
        value.store('feu', false)
      end
      allowed_values = [true, false]
      unless allowed_values.include?(value['feu'])
        raise ArgumentError, "Packages 'feu' key needs to be one of #{allowed_values}, instead you gave me: #{value['feu']}"
      end
    end

    def sort_packages(a)
      if a.nil?
        []
      else
        allowed_fields = ['name', 'action', 'fut', 'feu']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_packages(super)
    end

    def should=(values)
      super(sort_packages(values))
    end

    def insync?(is)
      sort_packages(is) == should
    end
  end

  newproperty(:scripts, array_matching: :all) do
    desc 'Scripts to run during the policy'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, 'Scripts are expected to be a Hash, given: #{value.class.name}'
      end

      unless value.key?('name')
        raise ArgumentError, "Scripts required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scripts 'name' value expected to be String, given: #{value['name'].class.name}"
      end

      unless value.key?('priority')
        value.store('priority', 'After')
      end
      allowed_values = ['Before', 'After']
      unless allowed_values.include?(value['priority'])
        raise ArgumentError, "Scripts 'priority' key needs to be one of #{allowed_values}, instead you gave me: #{value['priority']}"
      end

      unless value.key?('parameter4')
        value.store('parameter4', '')
      end
      unless value['parameter4'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter4' value expected to be String, given: #{value['parameter4'].class.name}"
      end

      unless value.key?('parameter5')
        value.store('parameter5', '')
      end
      unless value['parameter5'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter5' value expected to be String, given: #{value['parameter5'].class.name}"
      end

      unless value.key?('parameter6')
        value.store('parameter6', '')
      end
      unless value['parameter6'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter6' value expected to be String, given: #{value['parameter6'].class.name}"
      end

      unless value.key?('parameter7')
        value.store('parameter7', '')
      end
      unless value['parameter7'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter7' value expected to be String, given: #{value['parameter7'].class.name}"
      end

      unless value.key?('parameter8')
        value.store('parameter8', '')
      end
      unless value['parameter8'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter8' value expected to be String, given: #{value['parameter8'].class.name}"
      end

      unless value.key?('parameter9')
        value.store('parameter9', '')
      end
      unless value['parameter9'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter9' value expected to be String, given: #{value['parameter9'].class.name}"
      end

      unless value.key?('parameter10')
        value.store('parameter10', '')
      end
      unless value['parameter10'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter10' value expected to be String, given: #{value['parameter10'].class.name}"
      end

      unless value.key?('parameter11')
        value.store('parameter11', '')
      end
      unless value['parameter11'].is_a?(String)
        raise ArgumentError, "Scripts 'parameter11' value expected to be String, given: #{value['parameter11'].class.name}"
      end
    end

    def sort_scripts(a)
      if a.nil?
        []
      else
        allowed_fields = [
          'name',
          'priority',
          'parameter4',
          'parameter5',
          'parameter6',
          'parameter7',
          'parameter8',
          'parameter9',
          'parameter10',
          'parameter11',
        ]
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_scripts(super)
    end

    def should=(values)
      super(sort_scripts(values))
    end

    def insync?(is)
      sort_scripts(is) == should
    end
  end

  newproperty(:printers, array_matching: :all) do
    desc 'The printers which to add via the policy'

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Printers are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Printers required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Printers 'name' value expected to be String, given: #{value['name'].class.name}"
      end

      unless value.key?('action')
        value.store('action', 'install')
      end
      allowed_values = ['install', 'uninstall']
      unless allowed_values.include?(value['action'])
        raise ArgumentError, "Printers 'action' key needs to be one of #{allowed_values}, instead you gave me: #{value['action']}"
      end

      unless value.key?('make_default')
        value.store('make_default', false)
      end
      allowed_values = [true, false]
      unless allowed_values.include?(value['make_default'])
        raise ArgumentError, "Printers 'make_default' key needs to be one of #{allowed_values}, instead you gave me: #{value['make_default']}"
      end
    end

    def sort_printers(a)
      if a.nil?
        []
      else
        allowed_fields = ['name', 'action', 'make_default']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_printers(super)
    end

    def should=(values)
      super(sort_printers(values))
    end

    def insync?(is)
      sort_printers(is) == should
    end
  end

  newproperty(:reboot_message) do
    desc 'Message to display before computers restart'

    defaultto 'This computer will restart in 5 minutes. Please save anything you are working on and log out by choosing Log Out from the bottom of the Apple menu.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Reboot Message is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:startup_disk) do
    desc 'Which disk to boot computers to after reboot'

    defaultto 'Current Startup Disk'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Startup Disk is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = [
        'Current Startup Disk',
        'Currently Selected Startup Disk (No Bless)',
        'NetBoot',
        'macOS Installer',
        'Specify Local Startup Disk',
      ]
      unless allowed_values.include?(value)
        raise ArgumentError, "Startup Disk needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:specify_startup) do
    desc "Which specific startup disk to boot computers to (e.g. '/Volumes/SecondHD/')"

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Frequency is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:startup_disk] == 'Specify Local Startup Disk'
        value
      else
        ''
      end
    end
  end

  newproperty(:no_user_logged_in_action) do
    desc 'Reboot action to take if no user is logged in to the computer'

    defaultto 'Do not restart'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "No User Logged In Action is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = [
        'Restart if a package or update requires it',
        'Do not restart',
        'Restart immediately',
      ]
      unless allowed_values.include?(value)
        raise ArgumentError, "No User Logged In Action needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:user_logged_in_action) do
    desc 'Reboot action to take if a user is logged in to the computer'

    defaultto 'Do not restart'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "No User Logged In Action is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = [
        'Restart if a package or update requires it',
        'Do not restart',
        'Restart immediately',
        'Restart',
      ]
      unless allowed_values.include?(value)
        raise ArgumentError, "No User Logged In Action needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:minutes_until_reboot) do
    desc 'The amount of time to wait before the restart begins'

    defaultto 5

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Minutes Until Reboot is expected to be an Integer, given: #{value.class.name}"
      end
    end
  end

  newproperty(:start_reboot_timer_immediately, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to start the restart timer immediately without requiring the user to acknowledge the restart message'

    defaultto false
  end

  newproperty(:file_vault_2_reboot, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to restart FileVault 2-encrypted computers without requiring an unlock during the next startup'

    defaultto false
  end

  newproperty(:recon, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to force computers to submit updated inventory information to Jamf Pro'

    defaultto false
  end

  newproperty(:reset_name, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to change the computer name on computers to match the computer name in Jamf Pro'

    defaultto false
  end

  newproperty(:install_all_cached_packages, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to install all packages cached by Jamf Pro'

    defaultto false
  end

  newproperty(:fix_permissions, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to fix Disk Permissions (Not compatible with macOS v10.12 or later)'

    defaultto false
  end

  newproperty(:fix_byhost, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to fix ByHost Files'

    defaultto false
  end

  newproperty(:flush_system_cache, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to flush caches from /Library/Caches/ and /System/Library/Caches/, except for any com.apple.LaunchServices caches'

    defaultto false
  end

  newproperty(:flush_user_cache, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to flush caches from ~/Library/Caches/, ~/.jpi_cache/, and ~/Library/Preferences/Microsoft/Office version #/Office Font Cache.
          Note: Enabling this may cause problems with system fonts displaying unless a logout trigger or restart option is configured.'

    defaultto false
  end

  newproperty(:verify_startup_disk, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to verify the startup disk'

    defaultto false
  end

  newproperty(:search_by_path) do
    desc 'Search For File By Path - Full path to the file'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Search By Path is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:delete_file, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to delete file if found'

    defaultto false
  end

  newproperty(:locate_file) do
    desc 'Search For File By Filename - Name of the file, including the file extension. This field is case-sensitive and returns partial matches'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Locate File is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:update_locate_database, boolean: true, parent: Puppet::Property::Boolean) do
    desc "Whether to update the 'locate' database before searching for the file"

    defaultto false
  end

  newproperty(:spotlight_search) do
    desc 'Search For File Using Spotlight - File to search for. This field is not case-sensitive and returns partial matches'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Spotlight Search is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:search_for_process) do
    desc 'Search For Process - Name of the process. This field is case-sensitive and returns partial matches'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Search for Process is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:kill_process, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to kill process if found - This works with exact matches only'

    defaultto false
  end

  newproperty(:run_command) do
    desc "Command to execute on computers. This command is executed as the 'root' user"

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Run Command is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:policy_start_message) do
    desc 'Message to display before the policy runs'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Policy Start Message is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:allow_users_to_defer, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Allow user deferral and configure deferral type. A deferral limit must be specified for this to work'

    defaultto false
  end

  newproperty(:allow_deferral_until_utc) do
    desc 'Date/time at which deferrals are prohibited and the policy runs'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Allow Deferral Until UTC is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:allow_deferral_minutes) do
    desc 'Number of days after the user was first prompted by the policy at which the policy runs and deferrals are prohibited'

    defaultto 0

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Allow Deferral Minutes is expected to be an Integer, given: #{value.class.name}"
      end
    end
  end

  newproperty(:policy_complete_message) do
    desc 'Message to display when the policy is complete'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Policy Complete Message is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc 'URL of the JAMF API. Note: we will append "/JSSResource/policies" to the end of this. Default: https://127.0.0.1:8443'

    isrequired

    defaultto 'https://127.0.0.1:8443'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_url is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_username) do
    desc 'Username for authentication to the API.'

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_username is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_password) do
    desc 'Password for authentication to the API.'

    isrequired

    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:policy_name) do
    desc 'Name of the policy for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "policy_name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:is_cloud, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Check is server is cloud or internal'

    isrequired

    defaultto false
  end

  newparam(:auth_token) do
    desc 'Token used for authentication to the API.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "auth_token is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:jamf_cookie) do
    desc 'Cookie used to avoid cluster refresh issues with cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "jamf_cookie is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:conn_validator) do
    desc 'Title of the jamf_conn_validator resource to auto-require'

    defaultto 'jamf'
  end

  autorequire(:jamf_conn_validator) do
    @parameters[:conn_validator]
  end
end
