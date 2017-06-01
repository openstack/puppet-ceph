#
# Copyright (C) 2016 University of Michigan, funded by the NSF OSiRIS Project
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
# Author: Ben Meekhof <bmeekhof@umich.edu>
#
# Configures ceph radosgw packages and requirements
#
# === Parameters:
#
# [*pkg_radosgw*] Package name for the ceph radosgw.
#   Optional. Default is osfamily dependent (check ceph::params).

class ceph::rgw (
  $pkg_radosgw        = $::ceph::params::pkg_radosgw
) 
{
  package { $pkg_radosgw:
    ensure => installed,
    tag    => 'ceph',
  }

  # needed by rgw civetweb for libssl.sl and libcrypt.so
  # this may or may not be the package on other dists?
  package { 'openssl-devel': ensure => present }

  $unit_path = "/etc/systemd/system"
  $target_path = "${unit_path}/ceph-radosgw.target.wants"

  # Data directory for radosgw
  file { '/var/lib/ceph/radosgw': # missing in redhat pkg
    ensure => directory,
    mode   => '0755',
  }

  file { "radosgw-target-dir":
    ensure => directory,
    path => $target_path
  }

  file { "radosgw-target":
    ensure => 'link',
  }

  # used by rgw::instance when we put per-instance systemd unit over-rides in place
  exec {'ceph-rgw-reload-systemd':
    command => '/bin/systemctl daemon-reload',
    refreshonly => true
  }

  Ceph_config<||> ~> Service<| tag == 'rgw' |>
  Ceph::Key <||> -> Service<| tag == 'rgw' |>
  # in case rgw pools are being defined with ceph::pool resources
  Ceph::Pool <||> -> Service<| tag == 'rgw' |>
  Exec['ceph-rgw-reload-systemd'] -> Service<| tag == 'rgw' |>

}