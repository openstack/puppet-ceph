#
# Copyright (C) 2017 VEXXHOST, Inc.
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
# Author: Mohammed Naser <mnaser@vexxhost.com>
#
# == Define: ceph::mgr
#
# Installs and configures MGRs (ceph manager)
#
# === Parameters:
#
# [*title*] The manager ID.
#   Mandatory. An alphanumeric string uniquely identifying the manager.
#
# [*enable*] Whether to enable ceph-mgr instance on boot.
#   Optional. Default is true.
#
# [*ensure*] Configure the state of the service (running/stopped)
#   Optional. Defaults to running.
#
# [*cluster*] The ceph cluster
#   Optional. Same default as ceph.
#
# [*authentication_type*] Activate or deactivate authentication
#   Optional. Default to cephx.
#   Authentication is activated if the value is 'cephx' and deactivated
#   if the value is 'none'. If the value is 'cephx', then key must be provided.
#
# [*key*] Authentication key for ceph-mgr
#   Required if authentication_type is set to cephx
#
# [*inject_key*] Inject the key to the Ceph cluster
#   Optional. Defaults to false
#
define ceph::mgr (
  $enable              = true,
  $ensure              = running,
  $cluster             = 'ceph',
  $authentication_type = 'cephx',
  $key                 = undef,
  $inject_key          = false,
) {
  file { '/var/lib/ceph/mgr':
    ensure  => directory,
    owner   => 'ceph',
    group   => 'ceph',
    seltype => 'ceph_var_lib_t',
    tag     => 'ceph-mgr',
  } -> file { "/var/lib/ceph/mgr/${cluster}-${name}":
    ensure  => directory,
    owner   => 'ceph',
    group   => 'ceph',
    seltype => 'ceph_var_lib_t',
    tag     => 'ceph-mgr',
  }

  if $authentication_type == 'cephx' {
    if ! $key {
      fail('cephx requires a specified key for the manager daemon')
    }

    ceph::key { "mgr.${name}":
      secret       => $key,
      cluster      => $cluster,
      keyring_path => "/var/lib/ceph/mgr/${cluster}-${name}/keyring",
      cap_mon      => 'allow profile mgr',
      cap_osd      => 'allow *',
      cap_mds      => 'allow *',
      user         => 'ceph',
      group        => 'ceph',
      inject       => $inject_key,
      before       => Service["ceph-mgr@${name}"],
      require      => File["/var/lib/ceph/mgr/${cluster}-${name}"],
    }
  }

  service { "ceph-mgr@${name}":
    ensure => $ensure,
    enable => $enable,
    tag    => 'ceph-mgr',
  }

  Package<| tag == 'ceph' |>
  -> File<| tag == 'ceph-mgr' |>
  -> Service<| tag == 'ceph-mgr' |>
}
