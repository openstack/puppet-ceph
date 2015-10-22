#
# Copyright (C) 2014 Catalyst IT Limited.
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
# Author: Scott Merrill <skippy@skippy.net>
#
# Configures a Ceph radosgw using Apache 2.4 and FastCGI.
#
# See: http://docs.ceph.com/docs/master/radosgw/config/#create-a-gateway-configuration-file
#
## == Define: ceph::rgw::apache24
#
# The RGW id. An alphanumeric string uniquely identifying the RGW.
# ( example: radosgw.gateway )
#
### == Parameters
#
# [*admin_email*] Admin email for the radosgw reports.
#   Optional. Default is 'root@localhost'.
#
# [*docroot*] Location of the apache docroot.
#   Optional. Default is '/var/www'.
#
# [*pkg_radosgw*] Name of the radosgw package to install.
#   Optional. Default is distribution-specific.
#
# [*port*] TCP port on which Apache should listen.
#   Optional. Default is 80, or 443 if $ssl is true.
#
# [*print_continue*] Whether to enable HTTP "continue".
#   Optional. Default is false.
#
# [*socket_path*] Path to socket file.
#   Optional. Default is '/tmp/radosgw.sock'.
#
# [*ssl*] Wheher or not to use HTTPS for Apache.
#   Optional. Default is false.
#
# [*ssl_ca*] The CA file to use for HTTPS support.
#   Optional. No default.
#
# [*ssl_chain*] The CA chain file to use for HTTPS support.
#   Optional. No default.
#
# [*ssl_cert*] The public certificate to use for HTTPS support.
#   Optional. No default.
#
# [*ssl_key*] The private key to use for HTTPS support.
#   Optional. No default.
#
# [*syslog*] Whether or not to log to syslog.
#   Optional. Default is true.
#
# [*user*] System user to run radosgw
#   Optional. Default is distribution specific.
#
# [*vhost*] Hostname to use for the service.
#   Optional. Default is $fqdn.
#
# *** NOTE***
# Client keys do not need to be set on the radosgw if it
# is also a MON or OSD in the cluster.
# If the radosgw is neither, then you need to install the
# key.
# ceph::key { 'client.radosgw.gateway':
#   secret  => 'sOmeS3Cretv@LuehErE==',
#   cap_mon => 'allow rwx',
#   cap_osd => 'allow rwx',
#   user    => 'root',
#   group   => 'apache',
#   mode    => '0660',
#   inject  => true,
# }
# --- OR ---
#
# class ceph::keys($args = {}, $defaults = {}) {
#   create_resources(ceph::key, $args, $defaults)
# }
#
define ceph::rgw::apache24 (
  $admin_email    = 'root@localhost',
  $docroot        = '/var/www',
  $pkg_radosgw    = $::ceph::params::pkg_radosgw,
  $port           = undef,
  $print_continue = false,
  $socket_path    = $::ceph::params::rgw_socket_path,
  $ssl            = false,
  $ssl_ca         = undef,
  $ssl_chain      = undef,
  $ssl_cert       = undef,
  $ssl_key        = undef,
  $syslog         = true,
  $user           = $::ceph::params::user_radosgw,
  $vhost          = $::fqdn,
) {

  # detemine what TCP port to use
  if $port {
    # if the user specified a port, use it.
    $real_port = $port
  } elsif $ssl {
    # if no port specified, but SSL is enabled, use 443
    $real_port = '443'
  } else {
    # otherwise, use port 80
    $real_port = '80'
  }

  class { '::apache':
    default_mods  => false,
    default_vhost => false,
  }
  include ::apache::mod::alias
  include ::apache::mod::auth_basic
  include ::apache::mod::mime
  include ::apache::mod::rewrite
  apache::mod { 'env': }
  apache::mod { 'proxy_fcgi': }

  apache::vhost { "${vhost}-radosgw":
    access_log    => $syslog,
    default_vhost => true,
    docroot       => $docroot,
    error_log     => $syslog,
    port          => $real_port,
    proxy_dest    => "unix://${$socket_path}|fcgi://localhost:9000",
    servername    => $vhost,
    serveradmin   => $admin_email,
    rewrite_rule  => '.* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
    setenv        => 'proxy-nokeepalive 1',
    ssl           => $ssl,
    ssl_ca        => $ssl_ca,
    ssl_chain     => $ssl_chain,
    ssl_cert      => $ssl_cert,
    ssl_key       => $ssl_key,
  }

  file { '/var/run/ceph':
    ensure => directory,
    owner  => 'root',
    group  => 'apache',
    mode   => '0775',
  }

  ceph::rgw{ 'radosgw.gateway':
    pkg_radosgw        => $pkg_radosgw,
    user               => $user,
    rgw_dns_name       => $vhost,
    rgw_socket_path    => $socket_path,
    rgw_print_continue => $print_continue,
    require            => File['/var/run/ceph'],
  }

  package { 'radosgw-agent':
    ensure  => installed,
  }

}
