#
#   Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: David Gurtner <aldavud@crimson.ch>
#
# Profile for a Ceph mon
#
class ceph::profile::mon {
  require ceph::profile::base

  Ceph_Config<| |> ->
  ceph::mon { $::hostname:
    authentication_type => $ceph::profile::params::authentication_type,
    key                 => $ceph::profile::params::mon_key,
    keyring             => $ceph::profile::params::mon_keyring,
  }

  Ceph::Key {
    inject         => true,
    inject_as_id   => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
  }

  # this supports providing the key manually
  if $ceph::profile::params::admin_key {
    ceph::key { 'client.admin':
      secret       => $ceph::profile::params::admin_key,
      cap_mon      => 'allow *',
      cap_osd      => 'allow *',
      cap_mds      => 'allow',
      mode         => $ceph::profile::params::admin_key_mode,
    }
  }

  if $ceph::profile::params::bootstrap_osd_key {
    ceph::key { 'client.bootstrap-osd':
      secret           => $ceph::profile::params::bootstrap_osd_key,
      keyring_path     => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
      cap_mon          => 'allow profile bootstrap-osd',
    }
  }

  if $ceph::profile::params::bootstrap_mds_key {
    ceph::key { 'client.bootstrap-mds':
      secret           => $ceph::profile::params::bootstrap_mds_key,
      keyring_path     => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
      cap_mon          => 'allow profile bootstrap-mds',
    }
  }
}
