# @summary Installs and configures mysql on target host
# @api private
class jamf::mysql (
  #Hash             $db                    = $jamf::db,
  Optional[Hash]   $overrides             = $jamf::mysql_overrides,
  Optional[String] $root_pass             = $jamf::mysql_root_pass,
  Optional[String] $version               = $jamf::mysql_version,
  String           $os_arch               = $jamf::os_arch,
  String           $os_version            = $jamf::os_version,
  String           $repo_base_url         = $jamf::repo_base_url,
  String           $repo_gpgkey           = $jamf::repo_gpgkey,
  Boolean          $default_mysql_disable = $jamf::default_mysql_disable,
  $username = lookup('data::jamf::username'),
  $password = lookup('data::jamf::userpassword'),
) {
  notify { "db value: ${db}":
    message => $db,
  }

  notify { "version value: ${version}":
    message => $version,
  }

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
        baseurl  => $mysql_repo_url,
        descr    => "MySQL ${version} Community Server",
        enabled  => true,
        gpgcheck => true,
        gpgkey   => $repo_gpgkey,
      }
    }

    'Debian': {
      if $default_mysql_disable {
        exec { 'disable_mysql_module':
          command => 'apt-get purge mysql-server mysql-client mysql-common',
          path    => ['/usr/bin'],
          unless  => 'dpkg -l | grep mysql',
        }
      }
      #https://dev.mysql.com/get/mysql-apt-config_0.8.28-1_all.deb
      ## Add external repository for MySQL
      include apt
      $repo_base_url = "https://repo.mysql/apt"
      $mysql_repo_url = "${repo_base_url}/ubuntu/dists/focal/mysql-8.0/binary-amd64/Packages"
      #$mysql_repo_url ="https://downloads.mysql.com/archives/get/p/23/file/libmysqlclient21_8.0.33-1ubuntu22.04_amd64.deb"
      #$mysql_repo_url = "https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb"
      apt::source { 'mysql':
        location => $mysql_repo_url,
        repos    => 'main',
        key      => {
          id     => $repo_gpgkey,
          server => 'keyserver.ubuntu.com',
          # Note
          # The KeyID for MySQL 8.0.28 release packages and higher is 3A79BD29. For earlier MySQL releases, the keyID is 5072E1F5. Using an incorrect key can cause a key verification error.
        },
      }
    }

    default: {
      fail("The ${facts['os']['family']} operating system is not supported by the jamf::mysql class")
    }
  }

  ## Install and configure MySQL
  $mysql_client_package = case $facts['os']['family'] {
    'RedHat': { 'mysql-community-client' }
    'Debian': { 'default-mysql-client' }
    default:  { fail("Unsupported operating system: ${facts['os']['family']}") }
  }

  $mysql_client_require = case $facts['os']['family'] {
    'RedHat': { Yumrepo['mysql'] }
    'Debian': { Apt::Source['mysql'] }
    default:  { fail("Unsupported operating system: ${facts['os']['family']}") }
  }

  class { 'mysql::client':
    package_name => $mysql_client_package,
    require      => $mysql_client_require,
  }

  $mysql_package_name = case $facts['os']['family'] {
    'RedHat': { 'mysql-community-server' }
    'Debian': { 'mysql-server' }
    default: { fail("Unsupported operating system: ${facts['os']['family']}") }
  }

  class { 'mysql::server':
    package_name            => $mysql_package_name,
    override_options        => $overrides,
    manage_config_file      => true,
    remove_default_accounts => true,
    root_password           => $root_pass,
    service_name            => 'mysqld',
    require                 => Class['mysql::client'],
  }

  ## Create jamfsoftware database
  # Doku @ https://forge.puppet.com/modules/puppetlabs/mysql/reference#mysqldb
  #$db = Hash($db)
  # $db = { 'mydb':
  #   'name'     => 'jamfdatabase',
  #   'user'     => $username,
  #   'password' => Sensitive($password),
  #   'grant'    => ['SELECT', 'UPDATE'],
  # }
  # Big time issues with the $db hash it just wont be a hash here anymore idk how and why
  # thats why to do this in this way
  mysql::db { 'jamfdatabase':
    ensure   => present,
    user     => $username,
    password => $password,
    grant    => ['SELECT', 'UPDATE'],
    # require    => Class['jamf', 'mysql::server'],
  }

  # if validate_hash($db) {
  #   create_resources('::mysql::db', $db, {
  #       require => Class['jamf', 'mysql::server'],
  #   })
  # } else {
  #   notify { "db value validate: ${db}":
  #     message => validate_hash($db),
  #   }
  #   fail("Expected a Hash but got ${db} and ${validate_hash($db)}")
  # }
}
