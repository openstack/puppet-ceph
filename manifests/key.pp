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
# Handles ceph keys (cephx), generates keys, creates keyring files, injects
# keys into or delete keys from the cluster/keyring via ceph and ceph-authtool
# tools.
#
# == Define: ceph::key
#
# If keyid not specified, the resource title is used as ceph ID name, e.g. 'client.admin' or 'mon.'.  
#
# === Parameters:
#
# [*secret*] Key secret.
#   Mandatory. Can be created with ceph-authtool --gen-print-key.
#
# [*cluster*] The ceph cluster
#   Optional. Defaults to 'ceph' 
#
# [*keyid*] ceph key ID such as 'client.admin'
#   Optional.  Defaults to resource title.
#
# [*keyring_path*] Path to the keyring file.
#   Optional. Absolute path to the keyring file, including the file name.
#   Defaults to /etc/ceph/${cluster}.${name}.keyring.
#
# [*cap_mon*] cephx capabilities for MON access.
#   Optional. e.g. 'allow *'
#   Defaults to 'undef'.
#
# [*cap_osd*] cephx capabilities for OSD access.
#   Optional. e.g. 'allow *'
#   Defaults to 'undef'.
#
# [*cap_mds*] cephx capabilities for MDS access.
#   Optional. e.g. 'allow *'
#   Defaults to 'undef'.
#
# [*user*] Owner of the *keyring_path* file.
#   Optional. Defaults to 'root'.
#
# [*group*] Group of the *keyring_path* file.
#   Optional. Defaults to 'root'.
#
# [*mode*] Mode (permissions) of the *keyring_path* file.
#   Optional. Defaults to 0600.
#
# [*inject*] True if the key should be injected into the cluster.
#   Optional. Boolean value (true to inject the key).
#   Default to false.
#
# [*inject_as_id*] the ceph ID used to inject the key Optional. Only
#   taken into account if 'inject' was set to true, in which case it
#   overrides the ceph default if set to a value other than
#   undef. Default to undef.
#
# [*inject_keyring*] keyring file with injection credentials
#   Optional. Only taken into account if 'inject' was set to true. If
#   set to a value other than undef, it overrides the ceph default
#   inferred from the client name. Default to undef.
#
define ceph::key (
  $secret,
  $ensure  = present,
  $cluster = undef,
  $keyid = "${name}",
  $keyring_path = undef,
  $cap_mon = undef,
  $cap_osd = undef,
  $cap_mds = undef,
  $cap_mgr = undef,
  $user = 'root',
  $group = 'root',
  $mode = '0600',
  $inject = false,
  $inject_as_id = undef,
  $inject_keyring = undef,
) {

  if ($cluster) {
    $cluster_option = "--cluster ${cluster}"
    $cluster_name = $cluster
  } else {
    $cluster_name = 'ceph'
  }
  
  if ! $keyring_path {
    $keyring_file = "/etc/ceph/${cluster_name}.${keyid}.keyring"
  } else {
    $keyring_file = $keyring_path
  }

  if $cap_mon {
    $mon_caps = "--cap mon '${cap_mon}' "
  }
  if $cap_osd {
    $osd_caps = "--cap osd '${cap_osd}' "
  }
  if $cap_mds {
    $mds_caps = "--cap mds '${cap_mds}' "
  }
  if $cap_mgr {
    $mgr_caps = "--cap mgr '${cap_mgr}' "
  }
  $caps = "${mon_caps}${osd_caps}${mds_caps}${mgr_caps}"

  # this allows multiple defines for the same 'keyring file',
  # which is supported by ceph-authtool
  if ! defined(File[$keyring_file]) {
    file { $keyring_file:
      ensure  => $ensure,
      owner   => $user,
      group   => $group,
      mode    => $mode,
      require => Package['ceph'],
    }
  }

  if $ensure == 'present' {

    exec { "ceph-key-${cluster_name}.${keyid}":
      command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-authtool ${keyring_file} --name '${keyid}' --add-key '${secret}' ${caps}",
      unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
sed -n 'N;\\%.*${keyid}.*\\n\\s*key = ${secret}%p' ${keyring_file} | grep ${keyid}",
      require   => [ Package['ceph'], File[$keyring_file], ],
      logoutput => true,
    }
  }

  if $inject {
    if ($ensure == 'present') {

      if $inject_as_id {
        $inject_id_option = " --name '${inject_as_id}' "
      }

      if $inject_keyring {
        $inject_keyring_option = " --keyring '${inject_keyring}' "
      }

      Ceph_config<||> -> Exec["ceph-injectkey-${cluster_name}.${keyid}"]
      Ceph::Mon<||> -> Exec["ceph-injectkey-${cluster_name}.${keyid}"]
      exec { "ceph-injectkey-${cluster_name}.${keyid}":
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph ${cluster_option} ${inject_id_option} ${inject_keyring_option} auth add ${keyid} --in-file=${keyring_file}",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph ${cluster_option} ${inject_id_option} ${inject_keyring_option} auth get ${keyid} | grep ${secret}",
        require   => [ Package['ceph'], Exec["ceph-key-${cluster_name}.${keyid}"], ],
        logoutput => true,
      }
    } elsif ($ensure == 'absent') {
        exec { "ceph-rmkey-${cluster_name}.${keyid}":
          command => "/bin/ceph --cluster ${cluster_name} auth del ${keyid}",
          unless => "/bin/ceph --cluster ${cluster_name} auth get ${keyid} 2>&1 | grep ENOENT"
        }
    }

  }
}
