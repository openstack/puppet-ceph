#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: Ben Meekhof <bmeekhof@umich.edu>
#
# == Class: ceph::mds
#
# Installs and configures MDSs (ceph metadata servers).  No support for multiple MDS on one host.  
#
# === Parameters:
#
#
# [*cluster*] If cluster name is not 'ceph' define this appropriately
#
# [*instance*] Instance ID.  Defaults to hostname fact if not specified.
#
# [*mds_data*] The path to the MDS data.
#   Optional. Default provided by Ceph is '/var/lib/ceph/mds/$cluster-$id'.
#
# [*keyring*] The location of the keyring used by MDSs
#   Optional. Defaults to /var/lib/ceph/mds/$cluster-$id/keyring.
#
# [*ensure*] Defaults to 'present'.  'absent' will remove configs and disable service. 
#

define ceph::mds (
  $ensure       = 'present',
  $mds_data     = undef,
  $keyring      = undef,
  $config       = undef,
  $cluster      = 'ceph',
  $instance     = "${name}"
) {

  file { "/var/lib/ceph/mds/${cluster}-${instance}": 
    ensure => directory,
    owner => 'ceph',
    group => 'ceph',
    mode => '755',
    tag => 'ceph'
  }

  if $config {
    validate_hash($config)
    $config.each | $key, $value | {
      if ($value == 'absent') or ($ensure == 'absent') {
        $config_ensure = 'absent'
      } else {
        $config_ensure = 'present'
      }
      ceph_config {
        "${cluster}/mds/$key": value => $value, ensure => $config_ensure
      }
    }
  }

  if $ensure == 'present' {
    $service_state = 'running'
    $service_enable = true

    ceph_config {
      "${cluster}/mds/mds_data": value => $mds_data;
      "${cluster}/mds/keyring":  value => $keyring;
    }
  }  else {
    $service_state = 'stopped'
    $service_enable = false

    ceph_config {
      "${cluster}/mds/mds_data": ensure => absent;
      "${cluster}/mds/keyring":  ensure => absent;
    }
  }

  if $::operatingsystem == 'Ubuntu' {
    $service = "ceph-mds-${instance}"
    $init = 'upstart'
    Service {
      name     => "ceph-mds-${instance}",
      # workaround for bug https://projects.puppetlabs.com/issues/23187
      provider => $::ceph::params::service_provider,
      start    => "start ceph-mon id=${instance}",
      stop     => "stop ceph-mon id=${instance}",
      status   => "status ceph-mon id=${instance}"
    }
  } elsif ($::osfamily in ['RedHat', 'Debian']) and ((versioncmp($::operatingsystemmajrelease, '7') >= 0) or (versioncmp($::operatingsystemmajrelease, '8') >= 0)) {
    # use native systemd provider.  Not supporting older versions.
    $service = "ceph-mds@${instance}"

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

 # running multiple mds on one host is possible if we create separate init scripts.  Copy from the rgw resource define as an example. 
