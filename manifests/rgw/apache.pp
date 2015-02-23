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
# Configures a ceph radosgw apache frontend.
#
## == Define: ceph::rgw::apache
#
# The RGW id. An alphanumeric string uniquely identifying the RGW.
# ( example: radosgw.gateway )
#
### == Parameters
#
# [*pkg_fastcgi*] Package for the fastcgi module.
#   Optional. Default is osfamily dependent (check ceph::params).
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
#   Optional. Default is 443.
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
# [*ceph_apache_repo*] Wether to require the CEPH apache repo (ceph::repo::fastcgi).
#   Optional. Default is true. Check:
#   http://ceph.com/docs/master/install/install-ceph-gateway/
#   for more info on repository recommendations.
#
define ceph::rgw::apache (
  $pkg_fastcgi = $::ceph::params::pkg_fastcgi,
  $admin_email = 'root@localhost',
  $docroot = '/var/www',
  $fcgi_file = '/var/www/s3gw.fcgi',
  $rgw_dns_name = $::fqdn,
  $rgw_port = $::ceph::params::rgw_port,
  $rgw_socket_path = $::ceph::params::rgw_socket_path,
  $syslog = true,
  $ceph_apache_repo = true,
) {

  class { '::apache':
    default_mods  => false,
    default_vhost => false,
  }
  include ::apache::mod::alias
  include ::apache::mod::auth_basic
  apache::mod { 'fastcgi':
    package => $pkg_fastcgi,
  }
  include ::apache::mod::mime
  include ::apache::mod::rewrite

  apache::vhost { "${rgw_dns_name}-radosgw":
    servername        => $rgw_dns_name,
    serveradmin       => $admin_email,
    port              => $rgw_port,
    docroot           => $docroot,
    directories       => [{
      path            => $docroot,
      addhandlers     => [{
        handler    => 'fastcgi-script',
        extensions => ['.fcgi']
      }],
      allow_override  => ['All'],
      options         => ['+ExecCGI'],
      order           => 'allow,deny',
      allow           => 'from all',
      custom_fragment => 'AuthBasicAuthoritative Off',
    }],
    rewrite_rule      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
    access_log_syslog => $syslog,
    error_log_syslog  => $syslog,
    custom_fragment   => "
  FastCgiExternalServer ${fcgi_file} -socket ${rgw_socket_path}
  AllowEncodedSlashes On
  ServerSignature Off",
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
  if $ceph_apache_repo {
    case $::osfamily {
      'Debian': {
        Apt::Source['ceph-fastcgi']
        -> Package[$pkg_fastcgi]
      }
      'RedHat': {
        Yumrepo['ext-ceph-fastcgi']
        -> Package[$pkg_fastcgi]
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only supports osfamily Debian and RedHat")
      }
    }
  }

}
