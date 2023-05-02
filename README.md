# Jamf module for Puppet

## Table of Contents

1. [Description](#description)
2. [Support](#support)
3. [Setup - The basics of getting started with jamf](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference](#reference)

## Description

This module installs Jamf for on prem jamf servers and provides configuration options
for both on prem and cloud jamf servers.

## Support

This module is currently only tested on:

* RedHat 7

## Setup

### What jamf affects

* Installs and configures mysql to create jamf database.
* Configures firewall ports for jamf installer.
* Jamf tomcat service.

### Beginning with jamf

Since this module handles configuration for both jamf and jamf cloud servers, parameters that would normally be required
have been made optional. If you want a jamf server installation you will need to pass in configuration options as seen below.
Notice that you will need to provide your own jamf pro installer in order for this module to work correctly.

```puppet
class {'jamf':
  db              = 'example_db,
  installer_name  = 'example_installer_name',
  installer_path  = 'example_installer_path',
  java_opts       = 'JAVA_OPTS -example',
  organization    = 'example_org',
  activation_code = 'example_code',
  username        = 'example_user',
  password        = 'example_pass,
  is_cloud        = false,
  mysql_root_pass = 'example_mysql_pass',
  mysql_version   = 'example_mysql_version',
}
```

## Usage

If you already have jamf installed or you are dealing with a jamf cloud server and you
are just looking for configuration options, you can utilize this module's custom types
and providers. Below are the steps needed to configure both your jamf and jamf cloud servers
respectively. You can take a look at more info regarding specific types and providers
in the [Reference](#reference) section.

### Jamf Servers

You will first need to initialize the module by calling it as described in the
[Beginning with jamf](#beginning-with-jamf) section. After that you can call
the custom resources as needed to configure your jamf server.

### Jamf Cloud Servers

You will first need to initialize the module as shown below.

```puppet
class {'jamf':
  is_cloud = true,
}
```

You can then use the custom resources to configure your cloud jamf server as needed.

## Reference

Reference section has been moved to the [Reference.MD](https://github.com/EncoreTechnologies/puppet-jamf/blob/master/REFERENCE.md) file.
