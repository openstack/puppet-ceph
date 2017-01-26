#
#  Copyright (C) 2016 Keith Schincke
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
# Author: Keith Schincke <keith.schincke@gmail.com>
#
# == Class: ceph::profile::mirror
#
# Profile for Ceph rbd mirror
#
class ceph::profile::mirror {
  require ::ceph::profile::client
  $rbd_name = $::ceph::profile::params::rbd_mirror_client_name ? {
    undef   => 'openstack',
    default => $::ceph::profile::params::rbd_mirror_client_name,
  }
  ceph::mirror { $rbd_name:
  }
}
