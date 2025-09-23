#
# Copyright (C) 2014 Catalyst IT Limited.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
# Author: Oleksiy Molchanov <omolchanov@mirantis.com>
#
# Configures a ceph radosgw.
#
# == Define: ceph::rgw
#
# The RGW id. An alphanumeric string uniquely identifying the RGW.
# ( example: radosgw.gateway )
#
# === Parameters:
#
# [*pkg_radosgw*] Package name for the ceph radosgw.
#   Optional. Default is osfamily dependent (check ceph::params).
#
# [*rgw_ensure*] Whether to start radosgw service.
#   Optional. Default is running.
#
# [*rgw_enable*] Whether to enable radosgw service on boot.
#   Optional. Default is true.
#
# [*rgw_enable_apis*] Enables the specified APIs.
#   Optional. Default is undef.
#
# [*rgw_data*] The path where the radosgw data should be stored.
#   Optional. Default is '/var/lib/ceph/radosgw/ceph-${name}.
#
# [*user*] User running the web frontend.
#   Optional. Default is 'www-data'.
#
# [*keyring_path*] Location of keyring.
#   Optional. Default is '/etc/ceph/ceph.client.${name}.keyring'.
#
# [*log_file*] Log file to write to.
#   Optional. Default is '/var/log/ceph/radosgw.log'.
#
# [*rgw_dns_name*] Hostname to use for the service.
#   Optional. Default is $facts['networking']['fqdn'].
#
# [*rgw_socket_path*] Path to socket file.
#   Optional. Default is '/tmp/radosgw.sock'.
#
# [*rgw_print_continue*] True to send 100 codes to the client.
#   Optional. Default is false.
#
# [*rgw_port*] Port the rados gateway listens.
#   Optional. Default is undef.
#
# [*frontend_type*] What type of frontend to use
#   Optional. Default is civetweb, The other options are beast and
#   apache-proxy-fcgi.
#
# [*rgw_frontends*] Arguments to the rgw frontend
#   Optional. Default is undef.
#
# [*rgw_swift_url*] The URL for the Ceph Object Gateway Swift API.
#   Optional. Default is "http://${facts['networking']['fqdn']}:7480".
#
# [*rgw_swift_url_prefix*] The URL prefix for the Swift API.
#   Optional. Default is 'swift'.
#
# [*rgw_swift_account_in_url*] Whether or not the Swift account name should
#   be included in the Swift API URL.
#   Optional. Default is false.
#
# [*rgw_swift_versioning_enabled*] Enables the Object Versioning of OpenStack
#   Object Storage API
#   Optional. Default is false.
#
# [*rgw_trust_forwarded_https*] Trust the Forwarded and X-Forwarded-Proto
#   headers sent by the proxy when determining whether the connection is
#   secure.
#   Optional. Default is false
#
define ceph::rgw (
  $pkg_radosgw                          = undef,
  $rgw_ensure                           = 'running',
  $rgw_enable                           = true,
  $rgw_enable_apis                      = undef,
  Stdlib::Absolutepath $rgw_data        = "/var/lib/ceph/radosgw/ceph-${name}",
  $user                                 = undef,
  Stdlib::Absolutepath $keyring_path    = "/etc/ceph/ceph.client.${name}.keyring",
  Stdlib::Absolutepath $log_file        = '/var/log/ceph/radosgw.log',
  $rgw_dns_name                         = $facts['networking']['fqdn'],
  $rgw_socket_path                      = undef,
  $rgw_print_continue                   = false,
  $rgw_port                             = undef,
  $frontend_type                        = 'civetweb',
  $rgw_frontends                        = undef,
  $rgw_swift_url                        = "http://${facts['networking']['fqdn']}:7480",
  $rgw_swift_url_prefix                 = 'swift',
  $rgw_swift_account_in_url             = false,
  $rgw_swift_versioning_enabled         = false,
  $rgw_trust_forwarded_https            = false,
) {
  unless $name =~ /^radosgw\..+/ {
    fail("Define name must be started with 'radosgw.'")
  }

  include ceph::params
  $pkg_radosgw_real = pick($pkg_radosgw, $ceph::params::pkg_radosgw)
  $user_real = pick($user, $ceph::params::user_radosgw)
  $rgw_socket_path_real = pick($rgw_socket_path, $ceph::params::rgw_socket_path)

  if $rgw_enable_apis == undef {
    ceph_config { "client.${name}/rgw_enable_apis": ensure => absent }
  } else {
    ceph_config { "client.${name}/rgw_enable_apis": value => join(any2array($rgw_enable_apis), ',') }
  }

  ceph_config {
    "client.${name}/host":                         value => $facts['networking']['hostname'];
    "client.${name}/keyring":                      value => $keyring_path;
    "client.${name}/log_file":                     value => $log_file;
    "client.${name}/user":                         value => $user_real;
    "client.${name}/rgw_data":                     value => $rgw_data;
    "client.${name}/rgw_dns_name":                 value => $rgw_dns_name;
    "client.${name}/rgw_swift_url":                value => $rgw_swift_url;
    "client.${name}/rgw_swift_account_in_url":     value => $rgw_swift_account_in_url;
    "client.${name}/rgw_swift_url_prefix":         value => $rgw_swift_url_prefix;
    "client.${name}/rgw_swift_versioning_enabled": value => $rgw_swift_versioning_enabled;
    "client.${name}/rgw_trust_forwarded_https":    value => $rgw_trust_forwarded_https;
  }

  case $frontend_type {
    'beast': {
      ceph::rgw::beast { $name:
        rgw_frontends => $rgw_frontends,
      }
    }
    'civetweb': {
      warning('civetweb frontend has been removed in quincy release.')
      ceph::rgw::civetweb { $name:
        rgw_frontends => $rgw_frontends,
      }
    }
    'apache-proxy-fcgi': {
      warning('fastcgi frontend has been removed in quincy release.')
      $rgw_frontends_real = pick($rgw_frontends, 'fastcgi socket_port=9000 socket_host=127.0.0.1');
      ceph_config {
        "client.${name}/rgw_frontends":      value => $rgw_frontends_real;
        "client.${name}/rgw_print_continue": value => $rgw_print_continue;
        "client.${name}/rgw_socket_path":    value => $rgw_socket_path_real;
      }
    }
    default: {
      fail("Unsupported frontend_type: ${frontend_type}")
    }
  }

  stdlib::ensure_packages( $pkg_radosgw_real, {
    ensure => installed,
    tag    => 'ceph',
  })

  # Data directory for radosgw
  file { $rgw_data:
    ensure                  => directory,
    owner                   => 'root',
    group                   => 'root',
    mode                    => '0750',
    selinux_ignore_defaults => true,
  }

  # Log file for radosgw (ownership)
  file { $log_file:
    ensure                  => file,
    owner                   => $user_real,
    mode                    => '0640',
    selinux_ignore_defaults => true,
  }

  # NOTE(aschultz): this is the radowsgw service title, it may be different
  # than the actual service name
  $rgw_service = "radosgw-${name}"

  service { $rgw_service:
    ensure => $rgw_ensure,
    enable => $rgw_enable,
    name   => "ceph-radosgw@${name}",
    tag    => ['ceph-radosgw'],
  }

  Ceph_config<||> ~> Service<| tag == 'ceph-radosgw' |>
  Package<| tag == 'ceph' |> -> File[$log_file] -> Service<| tag == 'ceph-radosgw' |>
  Package<| tag == 'ceph' |> -> File[$rgw_data] -> Service<| tag == 'ceph-radosgw' |>
  Ceph::Pool<||> -> Service<| tag == 'ceph-radosgw' |>
}
