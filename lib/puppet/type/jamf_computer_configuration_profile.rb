require 'puppet/property/boolean'
require 'puppet/util/diff'

Puppet::Type.newtype(:jamf_computer_configuration_profile) do
  desc 'Manages Computer Configuration Profiles within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Computer Configuration Profile'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:category) do
    desc 'Category to add the profile to'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Category is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:description) do
    desc 'Brief explanation of the content or purpose of the profile'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Description is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:puppet_warning) do
    desc 'A string automatically added to the end of info to notate that this resource is managed by Puppet.'

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Info is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:distribution_method) do
    desc 'Method to use for distributing the profile'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Distribution Method is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['Install Automatically', 'Make Available in Self Service']
      unless allowed_values.include?(value)
        raise ArgumentError, "Distribution Method needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:user_removable, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to allow users to remove the profile using Self Service'

    munge do |value|
      if @resource[:distribution_method] == 'Make Available in Self Service'
        value
      else
        false
      end
    end
  end

  newproperty(:level) do
    desc 'Level at which to apply the profile'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Level is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['System', 'User']
      unless allowed_values.include?(value)
        raise ArgumentError, "Level needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newparam(:redeploy_on_update) do
    desc 'Who should receive updates when changes be made to the profile'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Redeploy On Update is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['Newly Assigned', 'All']
      unless allowed_values.include?(value)
        raise ArgumentError, "Redeploy On Update needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  newproperty(:payloads) do
    desc 'The settings to deploy via Configuration Profile'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Payload is expected to be a String, given: #{value.class.name}"
      end
    end

    # needed for calling lcs_diff below in insync?()
    include Puppet::Util::Diff

    def insync?(is)
      is_insync = super(is)
      # show diff of XML :)
      unless is_insync
        # diff the two strings
        diff_output = lcs_diff(is, should)
        send(@resource[:loglevel], "\n" + diff_output)
      end
      is_insync
    end
  end

  newproperty(:all_computers, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to assign the profile to all computers'

    defaultto false
  end

  newproperty(:all_jss_users, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to assign the profile to all users'

    defaultto false
  end

  newproperty(:scoped_computers, array_matching: :all) do
    desc 'Computers to assign the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
    desc 'Computer Groups to assign the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
    desc 'Buildings to assign the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
    desc 'Departments to assign the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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

  newproperty(:scoped_jss_users, array_matching: :all) do
    desc 'JSS Users to assign the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Users are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Users required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Users 'name' value expected to be String, given: #{value['name'].class.name}"
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

  newproperty(:scoped_jss_user_groups, array_matching: :all) do
    desc 'JSS User Groups to assign the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped User Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped User Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped User Groups 'name' value expected to be String, given: #{value['name'].class.name}"
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

  newproperty(:limited_users, array_matching: :all) do
    desc 'LDAP/Local Users to limit the assignment of the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
    desc 'LDAP Groups to limit the assignment of the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
    desc 'Network Segments to limit the assignment of the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
    desc 'iBeacons to limit the assignment of the profile to'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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
      # note: Puppet automatically detects if the value is an array and calls this validate()
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

  newproperty(:excluded_jss_users, array_matching: :all) do
    desc 'LDAP/Local Users for which to not assign the profile'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded JSS Users are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded JSS Users required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded JSS Users 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_jss_users(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_jss_users(super)
    end

    def should=(values)
      super(sort_jss_users(values))
    end

    def insync?(is)
      sort_jss_users(is) == should
    end
  end

  newproperty(:excluded_jss_user_groups, array_matching: :all) do
    desc 'LDAP Groups for which to not assign the profile'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded JSS User Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded JSS User Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded JSS User Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_jss_user_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_jss_user_groups(super)
    end

    def should=(values)
      super(sort_jss_user_groups(values))
    end

    def insync?(is)
      sort_jss_user_groups(is) == should
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/osxconfigurationprofiles' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:config_profile_name) do
    desc 'Name of the configuration profile for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "config_profile_name is expected to be a String, given: #{value.class.name}"
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
