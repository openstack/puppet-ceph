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
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#
# Configures a ceph radosgw apache frontend with mod_fastcgi.
#
## == Define: ceph::rgw::apache_fastcgi
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
# [*fcgi_file*] Path to the fcgi file.
#   Optional. Default is '/var/www/s3gw.cgi'.
#
# [*rgw_port*] Port the rados gateway listens.
#   Optional. Default is 80.
#
# [*rgw_dns_name*] Hostname to use for the service.
#   Optional. Default is $fqdn.
#
# [*rgw_socket_path*] Path to socket file.
#   Optional. Default is '/tmp/radosgw.sock'.
#
# [*syslog*] Whether or not to log to syslog.
#   Optional. Default is true.
#
# [*ceph_apache_repo*] Whether to require the CEPH apache repo (ceph::repo::fastcgi).
#   Optional. Default is true. Check:
#   http://docs.ceph.com/docs/master/install/install-ceph-gateway/
#   for more info on repository recommendations.
#
# [*apache_mods*] Whether to configure and enable a set of default Apache modules.
#   Optional. Defaults to false.
#
# [*apache_vhost*] Configures a default virtual host.
#   Optional. Defaults to false.
#
# [*apache_purge_configs*] Removes all other Apache configs and virtual hosts.
#   Optional. Defaults to true.
#
# [*apache_purge_vhost*] Whether to remove any configurations inside vhost_dir not managed
#   by Puppet.
#   Optional. Defaults to true.
#
# [*custom_apache_ports*] Array of ports to listen by Apache.
#   Optional. Works only if custom_apache set to true. Default is undef.
#
define ceph::rgw::apache_fastcgi (
  $admin_email          = 'root@localhost',
  $docroot              = '/var/www',
  $fcgi_file            = '/var/www/s3gw.fcgi',
  $rgw_dns_name         = $::fqdn,
  $rgw_port             = '80',
  $rgw_socket_path      = $::ceph::params::rgw_socket_path,
  $syslog               = true,
  $ceph_apache_repo     = true,
  $apache_mods          = false,
  $apache_vhost         = false,
  $apache_purge_configs = true,
  $apache_purge_vhost   = true,
  $custom_apache_ports  = undef,
) {

  warning ('apache_fastcgi is depricated and will be removed in two releases (P+2)')
  class { '::apache':
    default_mods    => $apache_mods,
    default_vhost   => $apache_vhost,
    purge_configs   => $apache_purge_configs,
    purge_vhost_dir => $apache_purge_vhost,
  }

  if $custom_apache_ports {
    apache::listen { $custom_apache_ports: }
  }

  if !$apache_mods {
    include ::apache::mod::auth_basic
  }

  include ::apache::mod::alias
  include ::apache::mod::mime
  include ::apache::mod::rewrite

  #Rewrite rule
  #Variable name shrunk in favor of not having
  #more than 140 chars per line
  $rr = '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]'

  apache::vhost { "${rgw_dns_name}-radosgw":
    servername     => $rgw_dns_name,
    serveradmin    => $admin_email,
    port           => $rgw_port,
    docroot        => $docroot,
    rewrite_rule   => $rr,
    access_log     => $syslog,
    error_log      => $syslog,
    fastcgi_server => $fcgi_file,
    fastcgi_socket => $rgw_socket_path,
    fastcgi_dir    => $docroot,
  }

  # radosgw fast-cgi script
  file { $fcgi_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => "#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n ${name}",
  }

  File[$fcgi_file]
  ~> Service['httpd']

  # dependency on ceph apache repo if set
  $pkg_fastcgi = $::apache::params::mod_packages['fastcgi']
  if $ceph_apache_repo {
    case $::osfamily {
      'Debian': {
        Apt::Source['ceph-fastcgi']
        -> Package[$pkg_fastcgi]
      }
      'RedHat': {
        if ($::osfamily == 'Redhat' and versioncmp($::operatingsystemrelease, '7.0') >= 0)
        {
          warning('puppetlabs puppet-apache dropped support for fastcgi on EL7')
          $pkg_fastcgi_real = 'mod_fastcgi'
        }
        else
        {
          $pkg_fastcgi_real = $pkg_fastcgi
        }
        Yumrepo['ext-ceph-fastcgi']
        -> Package[$pkg_fastcgi_real]
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, \
module ${module_name} only supports osfamily Debian and RedHat")
      }
    }
  }

}
