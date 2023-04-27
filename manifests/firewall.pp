# @summary Opens firewall ports for jamf
# @api private
class jamf::firewall {
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
