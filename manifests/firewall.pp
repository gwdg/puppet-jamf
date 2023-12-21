# @summary Opens firewall ports for jamf
# @api private
class jamf::firewall {
  case $facts['os']['family'] {
    'RedHat': {
      include firewalld
      firewalld_port { 'jamf_8080':
        ensure   => present,
        zone     => 'public',
        port     => 8080,
        protocol => 'tcp',
      }
      firewalld_port { 'jamf_8443':
        ensure   => present,
        zone     => 'public',
        port     => 8443,
        protocol => 'tcp',
      }
    }
    'Debian': {
      include firewall
      firewall { '100 allow 8080/tcp':
        dport  => 8080,
        proto  => 'tcp',
        action => 'accept',
      }
      firewall { '100 allow 8443/tcp':
        dport  => 8443,
        proto  => 'tcp',
        action => 'accept',
      }
    }
    default: {
      fail("The ${facts['os']['family']} operating system is not supported by the jamf::firewall class")
    }
  }
}
