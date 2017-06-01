#
# Copyright (C) 2014 Catalyst IT Limited.
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
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
# Author: Oleksiy Molchanov <omolchanov@mirantis.com>
# Author: Ben Meekhof <bmeekhof@umich.edu>
#
# Configures a ceph radosgw.
#
# == Define: ceph::rgw::instance
#
# If client_id param is not given separately, resource def must be an alphanumeric string uniquely identifying the RGW.
# This is to allow for unique resource definitions having same client ID (foreseen use case if more than one cluster rgw on node)
# ( example: radosgw.gateway )
#
# === Parameters:
#
# [*rgw_ensure*] Whether to start radosgw service.
#   Optional. Default is running.
#
# [*rgw_enable*] Whether to enable radosgw service on boot.
#   Optional. Default is true.
#
# [*rgw_data*] The path where the radosgw data should be stored.
#   Optional. Default is '/var/lib/ceph/radosgw/${cluster}-${name}.
#
# [*user*] User running the web frontend and owning daemon data directory
#   Optional. Default is 'ceph'.
#
# [*group*] Group running the web frontend and owning daemon data directory
#   Optional. Default is 'ceph'.
#
# [*keyring_path*] Location of keyring.
#   Optional. Default is '/etc/ceph/${name}.keyring'.
#
# [*log_file*] Log file to write to.
#   Optional. Default is '/var/log/ceph/${cluster}-radosgw.${client_id}.log'.
#
# [*rgw_dns_name*] Hostname to use for the service.
#   Optional. Default is $fqdn.
#
# [*rgw_socket_path*] Path to socket file.
#   Optional. Default is '/tmp/radosgw.sock'.
#
# [*rgw_print_continue*] True to send 100 codes to the client.
#   Optional. Default is false.
#
# [*rgw_port*] Port the rados gateway listens.
#   Optional. Default is undef.
#
# [*frontend_type*] What type of frontend to use
#   Optional. Default is apache-fastcgi. Other options are apache-proxy-fcgi or civetweb
#
# [*rgw_frontends*] Arguments to the rgw frontend
#   Optional. Default is 'fastcgi socket_port=9000 socket_host=127.0.0.1'. Example: "civetweb port=7480"
#
# [*syslog*] Whether or not to log to syslog.
#   Optional. Default is true.
#
# [*cpu_shares*] Set the CPUShares value in systemd unit.  If left undefined no setting is made.  
# The normal default priority is 1024.  Set lower/higher to decrease/increase priority of this 
# rgw instance relative to other services.  Reference systemd.resource-control(5) for more information.
#
# [*cpu_quota*] Set the CPUQuota value in systemd unit.  If left undefined no setting is made.  Value is a percentage of time 
# allowed on a single CPU.  Use a value > 100% to allow time on more than one CPU.  Do not include % character in setting.  
#
#

define ceph::rgw::instance (
  $ensure             = present,
  $cluster            = 'ceph',
  $enable             = true,
  $client_id          = "${name}",
  $rgw_data           = undef,
  $user               = $::ceph::params::user_radosgw,
  $group              = $::ceph::params::group_radosgw,
  $keyring_path       = undef,
  $log_file           = undef,
  $rgw_dns_name       = $::fqdn,
  $rgw_socket_path    = $::ceph::params::rgw_socket_path,
  $rgw_print_continue = false,
  $rgw_port           = undef,
  $frontend_type      = 'civetweb',
  $rgw_frontends      = undef,
  $ssl_cert           = undef,
  $ssl_ca_file        = undef,
  $port               = '80',
  $syslog             = false,
  $cpu_shares         = undef,
  $cpu_quota          = undef,
  $num_rados_handles  = undef,
  $thread_pool_size   = undef,
  $civetweb_num_threads = undef
) {

  unless $rgw_data { 
    $rgw_data_r = "/var/lib/ceph/radosgw/${cluster}-${client_id}" 
  } else {
      $rgw_data_r = $rgw_data
  }

  unless $log_file {
    $log_file_r = "/var/log/ceph/${cluster}-radosgw.${client_id}.log"
  } else{
    $log_file_r = $log_file
  }

  unless $keyring_path {
    $keyring_path_r = "${rgw_data_r}/keyring"
  } else{
    $keyring_path_r = $keyring_path
  }

  # ensure presence/absence of file touched in data dir indicating setup finished
  if ($enable == true) and ($ensure == 'present') {
      $ensure_init = 'present'
  } else {
      $ensure_init = 'absent'
  }

  if $ensure == 'present' {
    $ensure_service = 'running'
    $ensure_data_dir = 'directory'
  } else {
    $ensure_service = 'stopped'
    $ensure_data_dir = 'absent'
  }

  ceph_config {
    "${cluster}/client.${client_id}/host":                    value => $::hostname, ensure => $ensure;
    "${cluster}/client.${client_id}/keyring":                 value => $keyring_path_r, ensure => $ensure;
    "${cluster}/client.${client_id}/log_file":                value => $log_file_r, ensure => $ensure;
    "${cluster}/client.${client_id}/rgw_data":                value => $rgw_data_r, ensure => $ensure;
    "${cluster}/client.${client_id}/user":                    value => $user, ensure => $ensure;
    "${cluster}/client.${client_id}/rgw_num_rados_handles":   value => $num_rados_handles, ensure => $ensure;
    "${cluster}/client.${client_id}/rgw_thread_pool_size":    value => $thread_pool_size, ensure => $ensure;
  }

  if ($frontend_type == 'civetweb')
  {
    ceph::rgw::civetweb { "${name}":
      ensure => $ensure,
      rgw_frontends => $rgw_frontends,
      client_id =>  $client_id,
      ssl_cert => $ssl_cert,
      ssl_ca_file => $ssl_ca_file,
      cluster => $cluster,
      num_threads => $civetweb_num_threads,
      port => $port
    }
  }
  elsif ( ( $frontend_type == 'apache-fastcgi' ) or ( $frontend_type == 'apache-proxy-fcgi' ) )
  {
    ceph_config {
      "${cluster}/client.${client_id}/rgw_dns_client_id":       value => $rgw_dns_name, ensure => $ensure;
      "${cluster}/client.${client_id}/rgw_print_continue":      value => $rgw_print_continue, ensure => $ensure;
      "${cluster}/client.${client_id}/rgw_socket_path":         value => $rgw_socket_path, ensure => $ensure;
    }
    if $frontend_type == 'apache-fastcgi' {
      ceph_config {
        "${cluster}/client.${client_id}/rgw_port": value => $rgw_port, ensure => $ensure;
      }
    } elsif $frontend_type == 'apache-proxy-fcgi' {
      ceph_config {
        "${cluster}/client.${client_id}/rgw_frontends": value => $rgw_frontends, ensure => $ensure;
      }
    }
  }
  else
  {
    fail("Unsupported frontend_type: ${frontend_type}")
  }

  file { $rgw_data_r:
    ensure => $ensure_data_dir,
    owner  => $user,
    group  => $group,
    mode   => '0750',
  }

  # Log file for radosgw (ownership)
  # don't delete even if instance is set to absent
  # file { $log_file_r:
  #   ensure => present,
  #   owner  => $user,
  #   group => $group,
  #   mode   => '0640',
  # }

  # service definition
  if $::operatingsystem == 'Ubuntu' {
    $init_ready_file = 'done'

    Service {
      tag      => 'radosgw',
      name     => "radosgw-${name}",
      start    => "start radosgw id=${name}",
      stop     => "stop radosgw id=${name}",
      status   => "status radosgw id=${name}",
      provider => $::ceph::params::service_provider,
    }
  } elsif ($::operatingsystem == 'Debian') or ($::osfamily == 'RedHat') {
   
  # RHEL/CentOS7 systemd additions and over-rides for each instance.  No provision made for releases before Infernalis  
  
  if (($::osfamily == 'RedHat') and (versioncmp($::operatingsystemmajrelease, '7') >= 0)) {
    $init_ready_file = 'systemd'
    $service_name = "ceph-radosgw@${client_id}"
    $unit_path = $::ceph::rgw::unit_path
    $target_path = $::ceph::rgw::target_path

    File <| title == 'radosgw-target' |> { 
      path => "${target_path}/${service_name}.service",
      target => "${unit_path}/ceph-radosgw@.service"
    }

    file { "${unit_path}/${service_name}.service.d":
      ensure => directory
    } ->

    file { "${unit_path}/${service_name}.service.d/puppet-ceph.conf":
      content => template('ceph/ceph-radosgw.service.erb'),
      notify => [ Exec['ceph-rgw-reload-systemd'], Service["$service_name"] ]
    } 
  } else {
      $init_ready_file = 'sysvinit'
      $service_name = "radosgw-${name}"
      Service {
        tag      => [ 'ceph', 'rgw' ],
        name     => "${service_name}",
        start    => 'service radosgw start',
        stop     => 'service radosgw stop',
        status   => 'service radosgw status',
      }
    }
  }
  else {
    fail("operatingsystem = ${::operatingsystem} is not supported")
  }

  # for systemd this doesn't seem to matter but we'll follow the convention
  file { "${rgw_data_r}/${init_ready_file}":
        ensure => $ensure_init,
        before => Service["${service_name}"],
  }

  service { "${service_name}":
    tag    => [ 'ceph', 'rgw' ],
    ensure => $ensure_service,
    enable => $enable
  }

  Package<| tag == 'ceph' |> -> File['/var/lib/ceph/radosgw']
  File['/var/lib/ceph/radosgw']
  -> File[$rgw_data_r]
  -> Service["${service_name}"]
}
