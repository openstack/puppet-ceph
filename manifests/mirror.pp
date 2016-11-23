#
# Copyright (C) 2016 Keith Schincke
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
# Configures a ceph rbd mirroring
#
# == Define: ceph::mirror
#
# === Parameters:
#
# [*pkg_mirror*] Package name for RBD mirroring
#   Optional. Default is 'rbd-mirror'
#
# [*rbd_mirror_ensure*] Ensure RBD mirror is running
#   Optional. Default is 'running'
#
# [*rbd_mirror_enable*] Enable the RBD mirror service on boot
#   Optional. Default is true

define ceph::mirror (
  $pkg_mirror        = 'rbd-mirror',
  $rbd_mirror_ensure = 'running',
  $rbd_mirror_enable = true,
) {

  include ::stdlib

  ensure_resource( 'package',
    $pkg_mirror,
    {
      ensure => present,
      tag    => [ 'ceph' ],
    }
  )

  $service_name = "ceph-rbd-mirror@${name}"

  #Xenial reports 'debian' as the service provider
  #'systemd' should cover supported RHEL type systems
  if( ( $::service_provider == 'systemd' ) or
  ( $::operatingsystemrelease == '16.04' ) )
  {
    Service{
      name   => $service_name,
      enable => $rbd_mirror_enable,
    }
  }
  else {
    fail( 'Unsupported operating system. Ubuntu 16.04 and RedHat/CentOS 7 are supported' )
  }

  service { $service_name:
    ensure => $rbd_mirror_ensure,
    tag    => ['ceph-rbd-mirror']
  }

  Ceph_config<||> ~> Service<| tag == 'ceph-rbd-mirror' |>
  Package<| tag == 'ceph'|> -> Service<| tag == 'ceph-rbd-mirror' |>
}
