# @summary Opens firewall ports for jamf
# @api private
class jamf::firewall (
  $firewall = $jamf::firewall
) {
  $firewall_ensure = $firewall ? {
    true    => 'present',
    default => 'absent',
  }

  # $rootgroup = $facts['os']['family'] ? {
  #   'RedHat'                     => 'wheel',
  #   /(Debian|Ubuntu)/            => 'wheel',
  #   default                      => 'root',
  # }

  case $facts['os']['family'] {
    'RedHat': {
      include firewalld
      firewalld_port { 'jamf_8080':
        ensure   => $firewall_ensure,
        zone     => 'public',
        port     => 8080,
        protocol => 'tcp',
      }
      firewalld_port { 'jamf_8443':
        ensure   => $firewall_ensure,
        zone     => 'public',
        port     => 8443,
        protocol => 'tcp',
      }
    }
    'Debian': {
      include firewall
      firewall { '100 allow 8080/tcp':
        ensure => $firewall_ensure,
        dport  => 8080,
        proto  => 'tcp',
        action => 'accept',
      }
      firewall { '100 allow 8443/tcp':
        ensure => $firewall_ensure,
        dport  => 8443,
        proto  => 'tcp',
        action => 'accept',
      }
      firewall { '100 allow http and https access':
        ensure => $firewall_ensure,
        dport  => [80, 443],
        proto  => 'tcp',
        action => 'accept',
      }
      # TODO: gucken ob die anderen blockiert werden
    }
    default: {
      fail("The ${facts['os']['family']} operating system is not supported by the jamf::firewall class")
    }
  }
}
