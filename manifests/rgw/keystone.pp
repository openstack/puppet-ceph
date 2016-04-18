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
# Configures keystone auth/authz for the ceph radosgw.
#
### == Name
# # The RGW id. An alphanumeric string uniquely identifying the RGW.
# ( example: radosgw.gateway )
#
### == Parameters
#
# [*rgw_keystone_admin_token*] The keystone admin token.
#   Mandatory.
#
# [*rgw_keystone_url*] The internal or admin url for keystone.
#   Optional. Default is 'http://127.0.0.1:5000'
#
# [*rgw_keystone_version*] The api version for keystone.
#   Optional. Default is 'v2.0'
#
# [*rgw_keystone_accepted_roles*] Roles to accept from keystone.
#   Optional. Default is '_member_, Member'.
#   Comma separated list of roles.
#
# [*rgw_keystone_token_cache_size*] How many tokens to keep cached.
#   Optional. Default is 500.
#   Not useful when using PKI as every token is checked.
#
# [*rgw_keystone_revocation_interval*] Interval to check for expired tokens.
#   Optional. Default is 600 (seconds).
#   Not useful if not using PKI tokens (if not, set to high value).
#
# [*nss_db_path*] Path to NSS < - > keystone tokens db files.
#   Optional. Default is undef.
#
# [*user*] User running the web frontend.
#   Optional. Default is 'www-data'.
#
define ceph::rgw::keystone (
  $rgw_keystone_admin_token,
  $rgw_keystone_url = 'http://127.0.0.1:5000',
  $rgw_keystone_version = 'v2.0',
  $rgw_keystone_accepted_roles = '_member_, Member',
  $rgw_keystone_token_cache_size = 500,
  $rgw_keystone_revocation_interval = 600,
  $nss_db_path = '/var/lib/ceph/nss',
  $user = $::ceph::params::user_radosgw,
) {

  unless $name =~ /^radosgw\..+/ {
    fail("Define name must be started with 'radosgw.'")
  }

  ceph_config {
    "client.${name}/rgw_keystone_admin_token":         value => $rgw_keystone_admin_token;
    "client.${name}/rgw_keystone_url":                 value => $rgw_keystone_url;
    "client.${name}/rgw_keystone_accepted_roles":      value => $rgw_keystone_accepted_roles;
    "client.${name}/rgw_keystone_token_cache_size":    value => $rgw_keystone_token_cache_size;
    "client.${name}/rgw_keystone_revocation_interval": value => $rgw_keystone_revocation_interval;
    "client.${name}/rgw_s3_auth_use_keystone":         value => true;
    "client.${name}/nss_db_path":                      value => $nss_db_path;
  }

  # fetch the keystone signing cert, add to nss db
  $pkg_nsstools = $::ceph::params::pkg_nsstools
  ensure_resource('package', $pkg_nsstools, {'ensure' => 'present'})

  file { $nss_db_path:
    ensure => directory,
    owner  => $user,
    group  => 'root',
  }

  exec { "${name}-nssdb-ca":
    command => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate ${rgw_keystone_url}/${rgw_keystone_version}/certificates/ca -O /tmp/ca
openssl x509 -in /tmp/ca -pubkey | certutil -A -d ${nss_db_path} -n ca -t \"TCu,Cu,Tuw\"
",
    unless  => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
certutil -d ${nss_db_path} -L | grep ^ca
",
    user    => $user,
  }

  exec { "${name}-nssdb-signing":
    command => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate ${rgw_keystone_url}/${rgw_keystone_version}/certificates/signing -O /tmp/signing
openssl x509 -in /tmp/signing -pubkey | certutil -A -d ${nss_db_path} -n signing_cert -t \"P,P,P\"
",
    unless  => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
certutil -d ${nss_db_path} -L | grep ^signing_cert
",
    user    => $user,
  }

  Package[$pkg_nsstools]
  -> Package[$::ceph::params::packages]
  -> File[$nss_db_path]
  -> Exec["${name}-nssdb-ca"]
  -> Exec["${name}-nssdb-signing"]
  ~> Service["radosgw-${name}"]

}
