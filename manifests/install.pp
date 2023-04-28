# @summary Installs jamf using jamf pro installer
# @api private
class jamf::install (
  $jamf_owner     = $jamf::owner,
  $jamf_group     = $jamf::group,
  $install_dir    = $jamf::install_dir,
  $installer_name = $jamf::installer_name,
  $installer_path = $jamf::installer_path,
) {
  ## Create install directory
  file { $install_dir:
    ensure => directory,
    owner  => $jamf_owner,
    group  => $jamf_group,
    mode   => '0755',
  }

  ## Copy jamf PRO installer to target
  -> file { $installer_name:
    ensure => file,
    path   => "${install_dir}/${installer_name}",
    source => "${installer_path}/${installer_name}",
    owner  => $jamf_owner,
    group  => $jamf_group,
    mode   => '0755',
  }

  ## Run Jamf Installer
  # note: we need to run this command as sudo or the jamf installer with fail
  # to start tomcat and the install will fail
  exec { 'jamf_install':
    command => "sudo bash ${install_dir}/${installer_name} -- -y -d",
    path    => ['/bin'],
    creates => '/usr/local/jss/bin/jamf-pro',
    require => File[$installer_name],
  }
}
