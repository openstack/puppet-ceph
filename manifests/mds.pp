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
# [*mds_activate*] Switch to activate the '[mds]' section in the config.
#   Optional. Defaults to 'true'.
#
# [*mds_data*] The path to the MDS data.
#   Optional. Default provided by Ceph is '/var/lib/ceph/mds/$cluster-$id'.
#
# [*keyring*] The location of the keyring used by MDSs
#   Optional. Defaults to /var/lib/ceph/mds/$cluster-$id/keyring.
#
class ceph::mds (
  $mds_activate = true,
  $mds_data     = '/var/lib/ceph/mds/$cluster-$id',
  $keyring      = '/var/lib/ceph/mds/$cluster-$id/keyring',
) {

  # [mds]
  if $mds_activate {
    ceph_config {
      'mds/mds_data': value => $mds_data;
      'mds/keyring':  value => $keyring;
    }
  } else {
    ceph_config {
      'mds/mds_data': ensure => absent;
      'mds/keyring':  ensure => absent;
    }
  }
}
