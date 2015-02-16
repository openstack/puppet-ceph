#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
#
# == Class: ceph::params
#
# these parameters need to be accessed from several locations and
# should be considered to be constant
#
# === Parameters:
#
# [*packages*] The ceph package name
#   Optional. Defaults to 'ceph'
#
# [*rgw_port*] The TCP port for the rados gateway
#   Optional. Defaults to '80'
#
# [*rgw_socket_path*] The socket path of the rados gateway
#   Optional. Defaults to '/tmp/radosgw.sock'
#
class ceph::params (
  $packages = 'ceph', # just provide the minimum per default
  $rgw_port = 80,
  $rgw_socket_path = '/tmp/radosgw.sock',
) {

  case $::osfamily {
    'Debian': {
      $pkg_radosgw = 'radosgw'
      $user_radosgw = 'www-data'
      $pkg_fastcgi = 'libapache2-mod-fastcgi'
    }

    'RedHat': {
      $pkg_radosgw = 'ceph-radosgw'
      $user_radosgw = 'apache'
      $pkg_fastcgi = 'mod_fastcgi'
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only supports osfamily Debian or RedHat")
    }
  }
}
