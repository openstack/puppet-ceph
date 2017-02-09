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
# == Define: ceph::rgw
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
# [*user*] User running the web frontend.
#   Optional. Default is 'www-data'.
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

define ceph::rgw (
  $rgw_ensure         = 'running',
  $cluster            = 'ceph',
  $rgw_enable         = true,
  $client_id          = "${name}",
  $rgw_data           = undef,
  $user               = $::ceph::params::user_radosgw,
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

  unless $rgw_data { $rgw_data_r = "/var/lib/ceph/radosgw/${cluster}-${client_id}" }
  unless $keyring_path { $keyring_path_r  = "/etc/ceph/${cluster}.client.${client_id}.keyring" }
  unless $log_file { $log_file_r = "/var/log/ceph/${cluster}-radosgw.${client_id}.log" }

  ceph_config {
    "${cluster}/client.${client_id}/host":                    value => $::hostname;
    "${cluster}/client.${client_id}/keyring":                 value => $keyring_path_r;
    "${cluster}/client.${client_id}/log_file":                value => $log_file_r;
    "${cluster}/client.${client_id}/user":                    value => $user;
    "${cluster}/client.${client_id}/rgw_num_rados_handles":   value => $num_rados_handles;
    "${cluster}/client.${client_id}/rgw_thread_pool_size":    value => $thread_pool_size;
  }

  if ($frontend_type == 'civetweb')
  {
    ceph::rgw::civetweb { "${name}":
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
      "${cluster}/client.${client_id}/rgw_dns_client_id":       value => $rgw_dns_name;
      "${cluster}/client.${client_id}/rgw_print_continue": value => $rgw_print_continue;
      "${cluster}/client.${client_id}/rgw_socket_path":    value => $rgw_socket_path;
    }
    if $frontend_type == 'apache-fastcgi' {
      ceph_config {
        "${cluster}/client.${client_id}/rgw_port": value => $rgw_port;
      }
    } elsif $frontend_type == 'apache-proxy-fcgi' {
      ceph_config {
        "${cluster}/client.${client_id}/rgw_frontends": value => $rgw_frontends;
      }
    }
  }
  else
  {
    fail("Unsupported frontend_type: ${frontend_type}")
  }

  file { $rgw_data_r:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  # Log file for radosgw (ownership)
  file { $log_file_r:
    ensure => present,
    owner  => $user,
    mode   => '0640',
  }

  # service definition
  if $::operatingsystem == 'Ubuntu' {
    if $rgw_enable {
      file { "${rgw_data_r}/done":
        ensure => present,
        before => Service["radosgw-${name}"],
      }
    }

    Service {
      tag      => 'radosgw',
      name     => "radosgw-${name}",
      start    => "start radosgw id=${name}",
      stop     => "stop radosgw id=${name}",
      status   => "status radosgw id=${name}",
      provider => $::ceph::params::service_provider,
    }
  } elsif ($::operatingsystem == 'Debian') or ($::osfamily == 'RedHat') {
   
     #for RHEL/CentOS7 need systemd additions.  Not bothering to work for ceph release before Infernalis.  
  if (($::osfamily == 'RedHat') and (versioncmp($::operatingsystemmajrelease, '7') >= 0)) {

    $service_name = "${cluster}-radosgw@${client_id}"

    File <| title == 'radosgw-target-dir' |> {
      path => "/etc/systemd/system/${cluster}-radosgw.target.wants",
    }

    File <| title == 'radosgw-target' |> { 
      path => "/etc/systemd/system/${cluster}-radosgw.target.wants/${cluster}-radosgw@${client_id}.service",
      target => "/usr/lib/systemd/system/${cluster}-radosgw@.service"
    }

    if ! ($cluster == 'ceph') {
      File <| title == 'radosgw-systemd-target' |> {
        path => "/usr/lib/systemd/system/${cluster}-radosgw.target",
        source => 'file:////usr/lib/systemd/system/ceph-radosgw.target'
      }

      File <| title == 'radosgw-systemd-unit' |> {
        path => "/usr/lib/systemd/system/${cluster}-radosgw@.service", 
        source => 'file:////usr/lib/systemd/system/ceph-radosgw@.service',
      }
    }

    file { "/usr/lib/systemd/system/${cluster}-radosgw@${client_id}.service.d":
      ensure => directory,
      before => File["${name}-rgw-systemd-unit-override"]
    }

    # override or append unit settings for Environment, WantedBy, PartOf, CPUShares, CPUQuota
    file { "${name}-rgw-systemd-unit-override":
      path => "/usr/lib/systemd/system/${cluster}-radosgw@${client_id}.service.d/puppet-ceph.conf",
      ensure => present,
      content => template('ceph/radosgw.service.d.conf.erb'),
      notify => [ Exec['systemctl-reload-from-rgw'], Service["$service_name"] ]
    }

#     file_line { "unit-cluster-${cluster}":
#       path => "/usr/lib/systemd/system/${cluster}-radosgw@.service",
#       line => "Environment=CLUSTER=${cluster}",
#       match => 'Environment=CLUSTER=.*',
#       notify => Exec['systemctl-reload-from-rgw']
#     }
# 
#     file_line { "unit-wanted-${cluster}":
#       path => "/usr/lib/systemd/system/${cluster}-radosgw@.service",
#       line => "WantedBy=${cluster}-radosgw.target",
#       match => 'WantedBy=.*',
#       notify => Exec['systemctl-reload-from-rgw']
#     }
# 
#     file_line { "unit-shares-${cluster}":
#       path => "/usr/lib/systemd/system/${cluster}-radosgw@.service",
#       line => "CPUShares=$cpu_shares",
#       match => 'CPUShares=.*',
#       after => "[Service]",
#       notify => Exec['systemctl-reload-from-rgw']
# 
#     file_line { "unit-quota-${cluster}":
#       path => "/usr/lib/systemd/system/${cluster}-radosgw@.service",
#       line => "CPUQuota=${cpu_quota}%",
#       match => 'CPUQuota=.*',
#       after => "[Service]",
#       notify => Exec['systemctl-reload-from-rgw']
#     }

  } else {
      $service_name = "radosgw-${name}"
      Service {
        tag      => 'radosgw',
        name     => "${service_name}",
        start    => 'service radosgw start',
        stop     => 'service radosgw stop',
        status   => 'service radosgw status',
      }
    }

    if $rgw_enable {
      file { "${rgw_data_r}/sysvinit":
        ensure => present,
        before => Service["${service_name}"],
      }
    }

  }
  else {
    fail("operatingsystem = ${::operatingsystem} is not supported")
  }

  service { "${service_name}":
    tag    => 'radosgw',
    ensure => $rgw_ensure,
    enable => true
  }

  Ceph_config<||> -> Service["${service_name}"]
  Package<| tag == 'ceph' |> -> File['/var/lib/ceph/radosgw']
  Package<| tag == 'ceph' |> -> File[$log_file_r]
  File['/var/lib/ceph/radosgw']
  -> File[$rgw_data_r]
  -> Service["${service_name}"]
  File[$log_file_r] -> Service["${service_name}"]
  Ceph::Pool<||> -> Service["${service_name}"]
  Exec['systemctl-reload-from-rgw'] -> Service["${service_name}"]
}
