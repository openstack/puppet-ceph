#
# Copyright 2016 Red Hat, Inc.
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
# Author: Jan Provaznik <jprovazn@redhat.com>
#
# Manages operations on the fs in the cluster, such as creating or deleting
# fs, setting PG/PGP numbers, number of replicas, ...
#
# == Define: ceph::fs
#
# The name of the fs.
#
# === Parameters:
#
# [*name*] Name of the filesystem.
#   Optional. Default is cephfs.
#
# [*metadata_pool*] Name of a pool used for storing metadata.
#   Mandatory. Get one with `ceph osd pool ls`
#
# [*data_pool*] Name of a pool used for storing data.
#   Mandatory. Get one with `ceph osd pool ls`
#
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to $::ceph::params::exec_timeout
#
define ceph::fs (
  $metadata_pool,
  $data_pool,
  $exec_timeout = $::ceph::params::exec_timeout,
) {
  Ceph_config<||> -> Exec["create-fs-${name}"]
  Ceph::Pool<||> -> Exec["create-fs-${name}"]

  exec { "create-fs-${name}":
    command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph fs new ${name} ${metadata_pool} ${data_pool}",
    unless  => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph fs ls | grep 'name: ${name},'",
    timeout => $exec_timeout,
  }
}
