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
# Author: David Moreau Simard <dmsimard@iweb.com>
#
# == Class: ceph::profile::mon
#
# Profile for a Ceph mon
#
class ceph::profile::mon {
  require ::ceph::profile::base

  ceph::mon { $::hostname:
    authentication_type => $ceph::profile::params::authentication_type,
    key                 => $ceph::profile::params::mon_key,
    keyring             => $ceph::profile::params::mon_keyring,
    public_addr         => $ceph::profile::params::public_addr,
  }

  $defaults = {
    inject         => true,
    inject_as_id   => 'mon.',
    inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
  }

  if !empty($ceph::profile::params::client_keys) {
    class { '::ceph::keys':
      args     => $ceph::profile::params::client_keys,
      defaults => $defaults
    }
  }
}
