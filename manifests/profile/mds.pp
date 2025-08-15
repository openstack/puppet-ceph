#
#   Copyright (C) 2016 Red Hat, Inc.
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
# Author: Giulio Fidente <gfidente@redhat.com>
#
# == Class: ceph::profile::mds
#
# Profile for a Ceph mds
#
class ceph::profile::mds {
  require ceph::profile::base

  class { 'ceph::mds':
    public_addr => $ceph::profile::params::public_addr,
  }

  if !empty($ceph::profile::params::mds_key) {
    ceph::key { "mds.${facts['networking']['hostname']}":
      cap_mon      => 'allow profile mds',
      cap_osd      => 'allow rwx',
      cap_mds      => 'allow',
      inject       => true,
      keyring_path => "/var/lib/ceph/mds/ceph-${facts['networking']['hostname']}/keyring",
      secret       => $ceph::profile::params::mds_key,
      user         => 'ceph',
      group        => 'ceph',
    } -> Service<| tag == 'ceph-mds' |>
  }
}
