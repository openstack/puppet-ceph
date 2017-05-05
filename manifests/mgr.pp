#   Copyright (C) 2016 University of Michigan, funded by the NSF OSiRIS Project
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
# == Resource: ceph::mgr
#
# Installs and configures ceph-mgr service.  
#
# === Parameters:
#
#
# [*cluster*] If cluster name is not 'ceph' define this appropriately
#
# [*instance*] Instance ID.  Defaults to hostname fact if not specified.
#
# [*keyring*] The location of the keyring used by MGR
#   Optional. Defaults to /var/lib/ceph/mgr/$cluster-$instance/keyring.
#
# [*ensure*] Defaults to 'present'.  'absent' will remove configs and disable service. 
#


define ceph::mgr (
  $ensure       = 'present',
  $keyring      = undef,
  $cluster      = 'ceph',
  $instance     = "${name}"
) {

  file { "/var/lib/ceph/mgr/${cluster}-${instance}": 
    ensure => directory,
    owner => 'ceph',
    group => 'ceph',
    mode => '755',
    tag => 'ceph'
  }

  if $ensure == 'present' {
    $service_state = 'running'
    $service_enable = true

    ceph_config {
      "${cluster}/mgr/keyring": value => $keyring;
    }

  }  else {
    $service_state = 'stopped'
    $service_enable = false
    ceph_config {
      "${cluster}/mgr/keyring": ensure => absent;
    }
  }

  if $::operatingsystem == 'Ubuntu' {
    $service = "ceph-mgr-${instance}"
    $init = 'upstart'
    Service {
      name     => "ceph-mgr-${instance}",
      # workaround for bug https://projects.puppetlabs.com/issues/23187
      provider => $::ceph::params::service_provider,
      start    => "start ceph-mgr id=${instance}",
      stop     => "stop ceph-mgr id=${instance}",
      status   => "status ceph-mgr id=${instance}"
    }
  } elsif ($::osfamily in ['RedHat', 'Debian']) and ((versioncmp($::operatingsystemmajrelease, '7') >= 0) or (versioncmp($::operatingsystemmajrelease, '8') >= 0)) {
    # use native systemd provider.  Not supporting older versions.
    $service = "ceph-mgr@${instance}"

    if ! ($cluster == 'ceph') {
      file_line { "syconfig-${cluster}":
        path => "/etc/sysconfig/ceph",
        line => "CLUSTER=${cluster}",
        match => 'CLUSTER=.*',
        before => Service["${service}"],
        ensure => $ensure
      }
    }
  } else {
    fail("operatingsystem = ${::operatingsystem} is not supported")
  }

  service {"${service}":
    ensure => $service_state,
    enable => $service_enable,
    tag => 'ceph'
  }

}