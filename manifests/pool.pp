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
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to $::ceph::params::exec_timeout
#
define ceph::pool (
  $ensure = present,
  $pg_num = 64,
  $pgp_num = undef,
  $size = undef,
  $exec_timeout = $::ceph::params::exec_timeout,
) {

  if $ensure == present {

    Ceph_config<||> -> Exec["create-${name}"]
    Ceph::Mon<||> -> Exec["create-${name}"]
    Ceph::Key<||> -> Exec["create-${name}"]
    Ceph::Osd<||> -> Exec["create-${name}"]
    exec { "create-${name}":
      command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd pool create ${name} ${pg_num}",
      unless  => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd lspools | grep ' ${name},'",
      timeout => $exec_timeout,
    }

    exec { "set-${name}-pg_num":
      command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd pool set ${name} pg_num ${pg_num}",
      unless  => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test $(ceph osd pool get ${name} pg_num | sed 's/.*:\s*//g') -ge ${pg_num}",
      require => Exec["create-${name}"],
      timeout => $exec_timeout,
    }

    if $pgp_num {
      exec { "set-${name}-pgp_num":
        command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd pool set ${name} pgp_num ${pgp_num}",
        unless  => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test $(ceph osd pool get ${name} pgp_num | sed 's/.*:\s*//g') -ge ${pgp_num}",
        require => [Exec["create-${name}"], Exec["set-${name}-pg_num"]],
        timeout => $exec_timeout,
      }
    }

    if $size {
      exec { "set-${name}-size":
        command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd pool set ${name} size ${size}",
        unless  => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test $(ceph osd pool get ${name} size | sed 's/.*:\s*//g') -eq ${size}",
        require => Exec["create-${name}"],
        timeout => $exec_timeout,
      }
    }

  } elsif $ensure == absent {

    exec { "delete-${name}":
      command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd pool delete ${name} ${name} --yes-i-really-really-mean-it",
      onlyif  => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph osd lspools | grep ${name}",
      timeout => $exec_timeout,
    } -> Ceph::Mon<| ensure == absent |>

  } else {

    fail("*ensure* must be either present or absent - was '${ensure}'")

  }

}
