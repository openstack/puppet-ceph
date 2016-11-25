#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>
#
# == Class: ceph::mds
#
# Installs and configures MDSs (ceph metadata servers)
#
# === Parameters:
#
# [*public_addr*] The bind IP address.
#   Optional. The IPv(4|6) address on which MDS binds itself.
#
# [*pkg_mds*] Package name for the MDS service.
#   Optional. Defaults to the value of ceph::params::pkg_mds
#
# [*pkg_mds_ensure*] Ensure status for the pkg_mds package resources
#   Optional. Defaults to present.
#
# [*mds_activate*] Switch to activate the '[mds]' section in the config.
#   Optional. Defaults to true.
#
# [*mds_data*] The path to the MDS data.
#   Optional. Same default as ceph.
#
# [*mds_enable*] Whether to enable ceph-mds instance on boot.
#   Optional. Default is true.
#
# [*mds_ensure*] Whether to start the MDS service.
#   Optional. Default is running.
#
# [*mds_id*] The ID of the MDS instance.
#   Optional. Default is $::hostname
#
# [*keyring*] The location of the keyring used by MDSs
#   Optional. Same default as ceph.
#
# [*cluster*] The ceph cluster
#   Optional. Default to 'ceph'.
#
class ceph::mds (
  $public_addr    = undef,
  $pkg_mds        = $::ceph::params::pkg_mds,
  $pkg_mds_ensure = present,
  $mds_activate   = true,
  $mds_data       = undef,
  $mds_enable     = true,
  $mds_ensure     = 'running',
  $mds_id         = $::hostname,
  $keyring        = undef,
  $cluster        = 'ceph',
) inherits ceph::params {
  if $mds_data {
    $mds_data_real = $mds_data
  } else {
    $mds_data_real = "/var/lib/ceph/mds/${cluster}-${mds_id}"
  }

  if $keyring {
    $keyring_real = $keyring
  } else {
    $keyring_real = "${mds_data_real}/keyring"
  }

  Ceph_config<||> ~> Service<| tag == 'ceph-mds' |>
  Package<| tag == 'ceph' |>
  -> File[$mds_data_real]
  -> Service<| tag == 'ceph-mds' |>

  $mds_service_name = "ceph-mds@${mds_id}"

  service { $mds_service_name:
    ensure => $mds_ensure,
    enable => $mds_enable,
    tag    => ['ceph-mds']
  }

  package { $pkg_mds:
    ensure => $pkg_mds_ensure,
    tag    => 'ceph',
  }

  file { $mds_data_real:
    ensure                  => directory,
    owner                   => 'ceph',
    group                   => 'ceph',
    mode                    => '0750',
    selinux_ignore_defaults => true,
  }

  if $mds_activate {
    ceph_config {
      'mds/mds_data': value => $mds_data_real;
      'mds/keyring':  value => $keyring_real;
    }
    if $public_addr {
      ceph_config {
        "mds.${mds_id}/public_addr": value => $public_addr;
      }
    }
  } else {
    ceph_config {
      'mds/mds_data': ensure => absent;
      'mds/keyring':  ensure => absent;
    }
  }
}
