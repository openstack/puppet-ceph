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
# [*ensure*] Creates ( present ) or removes ( absent ) a file system.
#   Optional. Defaults to present.
#   If set to absent, it will drop the fs.
#
# [*cluster*] The ceph cluster
#   Optional. Defaults to ceph.
#
# DEPRECATED PARAMETERS
#
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to $ceph::params::exec_timeout
#
define ceph::fs (
  String[1] $metadata_pool,
  String[1] $data_pool,
  Enum['present', 'absent'] $ensure = present,
  String[1] $cluster = 'ceph',
  # DEPRECATED PARAMETERS
  Optional[Float[0]] $exec_timeout = undef,
) {
  if $exec_timeout {
    warning('The exec_timeout parameter is deprecated and has no effect')
  }

  Ceph_config<||> -> Ceph_fs[$name]
  Ceph::Pool<||> -> Ceph_fs[$name]

  ceph_fs { $name:
    ensure             => $ensure,
    metadata_pool_name => $metadata_pool,
    data_pool_name     => $data_pool,
    cluster            => $cluster,
  }
}
