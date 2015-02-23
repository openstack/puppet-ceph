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
# == Class: ceph::profile::base
#
# Base profile to install ceph and configure /etc/ceph/ceph.conf
#
class ceph::profile::base {
  include ::ceph::profile::params

  if ( $ceph::profile::params::manage_repo ) {
    Class['ceph::repo'] -> Class['ceph']

    class { '::ceph::repo':
      release => $ceph::profile::params::release,
    }
  }

  class { '::ceph':
    fsid                      => $ceph::profile::params::fsid,
    authentication_type       => $ceph::profile::params::authentication_type,
    osd_pool_default_pg_num   => $ceph::profile::params::osd_pool_default_pg_num,
    osd_pool_default_pgp_num  => $ceph::profile::params::osd_pool_default_pgp_num,
    osd_pool_default_size     => $ceph::profile::params::osd_pool_default_size,
    osd_pool_default_min_size => $ceph::profile::params::osd_pool_default_min_size,
    mon_initial_members       => $ceph::profile::params::mon_initial_members,
    mon_host                  => $ceph::profile::params::mon_host,
    cluster_network           => $ceph::profile::params::cluster_network,
    public_network            => $ceph::profile::params::public_network,
  }
}
