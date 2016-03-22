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
#   http://ceph.com/docs/master/install/install-ceph-gateway/
#   for more info on repository recommendations.
#
define ceph::rgw::apache (
  $admin_email      = 'root@localhost',
  $docroot          = '/var/www',
  $fcgi_file        = '/var/www/s3gw.fcgi',
  $rgw_dns_name     = $::fqdn,
  $rgw_port         = 80,
  $rgw_socket_path  = $::ceph::params::rgw_socket_path,
  $syslog           = true,
  $ceph_apache_repo = true,
) {

  warning ('Class rgw::apache is deprecated in favor of rgw::apache_fastcgi')

  ceph::rgw::apache_fastcgi { $name:
    admin_email      => $admin_email,
    docroot          => $docroot,
    fcgi_file        => $fcgi_file,
    rgw_dns_name     => $rgw_dns_name,
    rgw_port         => $rgw_port,
    rgw_socket_path  => $rgw_socket_path,
    syslog           => $syslog,
    ceph_apache_repo => $ceph_apache_repo,
  }
}
