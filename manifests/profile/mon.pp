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
# Author: David Gurtner <david@nine.ch>
#
# Profile for a Ceph mon
#
class ceph::profile::mon inherits ceph::profile::base {
  $admin_key = hiera('ceph::key::admin')
  $mon_key = hiera('ceph::key::mon')
  $bootstrap_osd_key = hiera('ceph::key::bootstrap_osd')
  $authentication_type = hiera('ceph::conf::authentication_type')

  ceph::mon { $hostname:
    authentication_type => $authentication_type,
    key                 => $mon_key,
  }

  ceph::key { 'mon client.admin':
    secret   => $admin_key,
    caps_mon => 'allow *',
    caps_osd => 'allow *',
    caps_mds => 'allow',
    inject   => true,
  }

  ceph::key { 'mon client.bootstrap-osd':
    secret   => $bootstrap_osd_key,
    caps_mon => 'profile bootstrap-osd',
    inject   => true,
  }
}
