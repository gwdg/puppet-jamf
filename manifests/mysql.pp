# @summary Installs and configures mysql on target host
# @api private
class jamf::mysql (
  Optional[Hash]   $db                    = $jamf::db,
  Optional[Hash]   $overrides             = $jamf::mysql_overrides,
  Optional[String] $root_pass             = $jamf::mysql_root_pass,
  Optional[String] $version               = $jamf::mysql_version,
  String           $os_arch               = $jamf::os_arch,
  String           $os_version            = $jamf::os_version,
  String           $repo_base_url         = $jamf::repo_base_url,
  String           $repo_gpgkey           = $jamf::repo_gpgkey,
  Boolean          $default_mysql_disable = $jamf::default_mysql_disable
) {

  # Set final MySQL repo URL

  case $facts['os']['family'] {
    'RedHat': {
      if $default_mysql_disable {
        exec { 'disable_mysql_module':
          command => 'yum -y module disable mysql',
          path   => ['/bin'],
          unless => 'yum module list --disabled | grep mysql',
        }
      }

      ## Add external repository for MySQL
      $mysql_repo_url = "${repo_base_url}/mysql-${version}-community/el/${os_version}/${os_arch}/"
      yumrepo { 'mysql':
        baseurl => $mysql_repo_url,
        descr   => "MySQL ${version} Community Server",
        enabled => true,
        gpgcheck => true,
        gpgkey  => $repo_gpgkey,
      }
    }

    'Debian': {
      if $default_mysql_disable {
        exec { 'disable_mysql_module':
          command => 'apt-get purge mysql-server mysql-client mysql-common',
          path   => ['/usr/bin'],
          unless => 'dpkg -l | grep mysql',
        }
      }
      #https://dev.mysql.com/get/mysql-apt-config_0.8.28-1_all.deb
      ## Add external repository for MySQL
      #$mysql_repo_url = "${repo_base_url}/ubuntu/dists/focal/mysql-8.0/binary-amd64/Packages"
      $mysql_repo_url ="https://dev.mysql.com/get/mysql-apt-config_0.8.28-1_all.deb"
      apt::source { 'mysql':
        location => $mysql_repo_url,
        release => $release_name,
        repos   => 'main',
        key     => {
          id    => $repo_gpgkey,
          server => 'keyserver.ubuntu.com',
        },
      }
    }

    default: {
      fail("Unsupported OS family: ${facts['os']['family']}")
    }
  }

  ## Install and configure MySQL
  class { 'mysql::client':
    package_name => case $facts['os']['family'] {
      'RedHat': 'mysql-community-client',
      'Debian': 'mysql-client',
      default: fail("Unsupported operating system: ${facts['os']['family']}"),
    },
    require => case $facts['os']['family'] {
      'RedHat': Yumrepo['mysql'],
      'Debian': Apt::Source['mysql'],
      default: fail("Unsupported operating system: ${facts['os']['family']}"),
    },
  }


  class { 'mysql::server':
    package_name => case $facts['os']['family'] {
      'RedHat': 'mysql-community-client',
      'Debian': 'mysql-client',
      default: fail("Unsupported operating system: ${facts['os']['family']}"),
    },
    override_options        => $overrides,
    manage_config_file      => true,
    remove_default_accounts => true,
    root_password           => $root_pass,
    service_name            => 'mysqld',
    require                 => Class['mysql::client'],
  }

  ## Create jamfsoftware database
  create_resources('::mysql::db', $db, {
      require => Class['mysql::server'],
  })
}
