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
# [*pgk_cephrgw*] Package name for the ceph radosgw.
#   Optional. Default is osfamily dependent (check ceph::params).
#
# [*rgw_data*] The path where the radosgw data should be stored.
#   Optional. Default is '/var/lib/ceph/radosgw/${cluster}-${name}.
#
# [*user*] User running the web frontend.
#   Optional. Default is 'www-data'.
#
# [*keyring_path*] Location of keyring.
#   Optional. Default is '/etc/ceph/${name}.keyring'.
#
# [*log_file*] Log file to write to.
#   Optional. Default is '/var/log/ceph/radosgw.log'.
#
# [*rgw_dns_name*] Hostname to use for the service.
#   Optional. Default is $fqdn.
#
# [*rgw_socket_path*] Path to socket file.
#   Optional. Default is '/tmp/radosgw.sock'.
#
# [*rgw_print_continue*] True to send 100 codes to the client.
#   Optional. Default is true.
#
# [*rgw_port*] Port the rados gateway listens.
#   Optional. Default is 443.
#
# [*syslog*] Whether or not to log to syslog.
#   Optional. Default is true.
#
define ceph::rgw (
  $pkg_radosgw = $::ceph::params::pkg_radosgw,
  $rgw_data = "/var/lib/ceph/radosgw/ceph-${name}",
  $user = $::ceph::params::user_radosgw,
  $keyring_path = "/etc/ceph/ceph.client.${name}.keyring",
  $log_file = '/var/log/ceph/radosgw.log',
  $rgw_dns_name = $::fqdn,
  $rgw_socket_path = $::ceph::params::rgw_socket_path,
  $rgw_print_continue = true,
  $rgw_port = $::ceph::params::rgw_port,
  $syslog = true,
) {

  ceph_config {
    "client.${name}/host":               value => $::hostname;
    "client.${name}/keyring":            value => $keyring_path;
    "client.${name}/log_file":           value => $log_file;
    "client.${name}/rgw_dns_name":       value => $rgw_dns_name;
    "client.${name}/rgw_port":           value => $rgw_port;
    "client.${name}/rgw_print_continue": value => $rgw_print_continue;
    "client.${name}/rgw_socket_path":    value => $rgw_socket_path;
    "client.${name}/user":               value => $user;
  }

  package { $pkg_radosgw:
    ensure => installed,
    tag    => 'ceph',
  }

  # Data directory for radosgw
  file { '/var/lib/ceph/radosgw': # missing in redhat pkg
    ensure => directory,
    mode   => '0755',
  }
  file { $rgw_data:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  # Log file for radosgw (ownership)
  file { $log_file:
    ensure => present,
    owner  => $user,
    mode   => '0640',
  }

  # service definition
  if $::operatingsystem == 'Ubuntu' {
    $init = 'upstart'
    Service {
      name     => "radosgw-${name}",
      provider => 'init',
      start    => "start radosgw id=${name}",
      stop     => "stop radosgw id=${name}",
      status   => "status radosgw id=${name}",
    }
  } elsif ($::operatingsystem == 'Debian') {
    $init = 'sysvinit'
    Service {
      name     => "radosgw-${name}",
      start    => "service radosgw start id=${name}",
      stop     => "service radosgw stop id=${name}",
      status   => "service radosgw status id=${name}",
    }
  } elsif ($::osfamily == 'RedHat') {
    $init = 'sysvinit'
    Service {
      name     => "radosgw-${name}",
      start    => "service ceph-radosgw start id=${name}",
      stop     => "service ceph-radosgw stop id=${name}",
      status   => "service ceph-radosgw status id=${name}",
    }
  }
  else {
    fail("operatingsystem = ${::operatingsystem} is not supported")
  }

  service { "radosgw-${name}":
    ensure => running,
  }

  Package<| tag == 'ceph' |>
  -> File['/var/lib/ceph/radosgw']
  -> File[$rgw_data]
  -> File[$log_file]
  -> Ceph::Pool<||>
  -> Service["radosgw-${name}"]

}
