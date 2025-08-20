#
# Copyright (C) 2014 Catalyst IT Limited.
# Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: David Gurtner <aldavud@crimson.ch>
#
# Manages operations on the pools in the cluster, such as creating or deleting
# pools, setting PG/PGP numbers, number of replicas, ...
#
# == Define: ceph::pool
#
# The name of the pool.
#
# === Parameters:
#
# [*ensure*] Creates ( present ) or removes ( absent ) a pool.
#   Optional. Defaults to present.
#   If set to absent, it will drop the pool and all its data.
#
# [*cluster*] The ceph cluster
#   Optional. Defaults to ceph.
#
# [*pg_num*] Number of PGs for the pool.
#   Optional. Default is 64 ( but you probably want to pass a value here ).
#   Number of Placement Groups (PGs) for a pool, if the pool already
#   exists this may increase the number of PGs if the current value is lower.
#   Check http://ceph.com/docs/master/rados/operations/placement-groups/.
#
# [*pgp_num*] Same as for pg_num.
#   Optional. Default is undef.
#
# [*size*] Replica level for the pool.
#   Optional. Default is undef.
#   Increase or decrease the replica level of a pool.
#
# [*tag*] Pool tag.
#   Optional. Default is undef.
#   cephfs,rbd,rgw or freeform for custom application.
#
# DEPRECATED PARAMETERS
#
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to $ceph::params::exec_timeout
#
define ceph::pool (
  Enum['present', 'absent'] $ensure = present,
  String[1] $cluster = 'ceph',
  Integer[0] $pg_num = 64,
  Optional[Integer[0]] $pgp_num = undef,
  Optional[Integer[0]] $size = undef,
  Optional[String[1]] $tag = undef,
  # DEPRECATED PARAMETERS
  Optional[Float[0]] $exec_timeout = undef,
) {
  include ceph::params

  if $exec_timeout {
    warning('The exec_timeout parameter is deprecated and has no effect')
  }

  if $pgp_num and ($pgp_num > $pg_num) {
    fail('pgp_num should not exceed pg_num')
  }

  Ceph_config<||> -> Ceph_pool[$name]
  Ceph::Mon<||> -> Ceph_pool[$name]
  Ceph::Key<||> -> Ceph_pool[$name]
  Ceph::Osd<||> -> Ceph_pool[$name]

  ceph_pool { $name:
    ensure      => $ensure,
    pg_num      => $pg_num,
    pgp_num     => $pgp_num,
    size        => $size,
    cluster     => $cluster,
    application => $tag,
  }
}
