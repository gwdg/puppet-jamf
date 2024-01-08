# @summary Manages the jamf service for on premises jamf servers
# @api private
class jamf::on_prem (
  String $max_backup_age = $jamf::max_backup_age
) {
  # contain everything and then order at bottom
  contain jamf::mysql
  contain jamf::firewall
  contain jamf::install
  contain jamf::tomcat

  case $facts['os']['family'] {
    'RedHat': {
      Class['jamf::mysql'] -> Class['jamf::firewall'] -> Class['firewalld::reload'] -> Class['jamf::install'] -> Class['jamf::tomcat']
    }
    'Debian': {
      Class['jamf::mysql'] -> Class['jamf::firewall']  -> Class['jamf::install'] -> Class['jamf::tomcat']
      # Could not find a way to reload the Firewall with with the "puppetlabs-firewall". I think iptables dont need a reload
    }
    default: {
      fail("The ${facts['os']['family']} operating system is not supported by the jamf::on_prem class")
    }
  }

# TODO: backup auf 7 tage
# TODO: parametrisiere den pfad
  # Clean up backups
  cron { 'Cleanup Jamf Backups':
    command => "find /usr/local/jss/backups/ -mindepth 2 -maxdepth 2 -mtime ${max_backup_age} | xargs rm -rf",
    user    => 'root',
    hour    => 2,
  }
}
