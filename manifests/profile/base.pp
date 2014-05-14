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
# Base profile to install ceph and configure /etc/ceph/ceph.conf 
#
class ceph::profile::base {
  $release = hiera('ceph::release')
  $fsid = hiera('ceph::conf::fsid')
  $authentication_type = hiera('ceph::conf::authentication_type')
  $osd_pool_default_pg_num = hiera('ceph::conf::osd_pool_default_pg_num')
  $osd_pool_default_pgp_num = hiera('ceph::conf::osd_pool_default_pgp_num')
  $osd_pool_default_size = hiera('ceph::conf::osd_pool_default_size')
  $osd_pool_default_min_size = hiera('ceph::conf::osd_pool_default_min_size')
  $mon_initial_members = hiera('ceph::conf::mon_initial_members')
  $mon_host = hiera('ceph::conf::mon_host')
  $cluster_network = hiera('ceph::conf::cluster_network')
  $public_network = hiera('ceph::conf::public_network')

  class { 'ceph::repo':
    release => $release,
  } ->

  class { 'ceph':
    fsid                      => $fsid,
    authentication_type       => $authentication_type,
    osd_pool_default_pg_num   => $osd_pool_default_pg_num,
    osd_pool_default_pgp_num  => $osd_pool_default_pgp_num,
    osd_pool_default_size     => $osd_pool_default_size,
    osd_pool_default_min_size => $osd_pool_default_min_size,
    mon_initial_members       => $mon_initial_members,
    mon_host                  => $mon_host,
    cluster_network           => $cluster_network,
    public_network            => $public_network,
  }

}
