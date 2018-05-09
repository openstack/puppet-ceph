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
#   Required if rgw_keystone_version is v2.0.
#
# [*rgw_keystone_url*] The internal or admin url for keystone.
#   Optional. Default is 'http://127.0.0.1:5000'
#
# [*rgw_keystone_version*] The api version for keystone.
#   Possible values 'v2.0', 'v3'
#   Optional. Default is 'v2.0'
#
# [*rgw_keystone_accepted_roles*] Roles to accept from keystone.
#   Optional. Default is 'Member'.
#   Comma separated list of roles.
#
# [*rgw_keystone_token_cache_size*] How many tokens to keep cached.
#   Optional. Default is 500.
#   Not useful when using PKI as every token is checked.
#
# [*rgw_s3_auth_use_keystone*] Whether to enable keystone auth for S3.
#   Optional. Default to true.
#
# [*use_pki*] Whether to use PKI related configuration.
#   Optional. Default to true.
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
# [*rgw_keystone_admin_domain*] The name of OpenStack domain with admin
#   privilege when using OpenStack Identity API v3
#   Optional. Default is undef
#
# [*rgw_keystone_admin_project*] The name of OpenStack project with admin
#   privilege when using OpenStack Identity API v3
#   Optional. Default is 'openstack'
#
# [*rgw_keystone_admin_user*] The user name of OpenStack tenant with admin
#   privilege (Service Tenant)
#   Required if rgw_keystone_version is 'v3'.
#
# [*rgw_keystone_admin_password*] The password for OpenStack admin user
#   Required if rgw_keystone_version is 'v3'.
#
# [*rgw_keystone_implicit_tenants*] Set 'true' for a private tenant
#   for each user.
#   Defaults is true

define ceph::rgw::keystone (
  $rgw_keystone_admin_token         = undef,
  $rgw_keystone_url                 = 'http://127.0.0.1:5000',
  $rgw_keystone_version             = 'v2.0',
  $rgw_keystone_accepted_roles      = 'Member',
  $rgw_keystone_token_cache_size    = 500,
  $rgw_s3_auth_use_keystone         = true,
  $use_pki                          = true,
  $rgw_keystone_revocation_interval = 600,
  $nss_db_path                      = '/var/lib/ceph/nss',
  $user                             = $::ceph::params::user_radosgw,
  $rgw_keystone_admin_domain        = $::ceph::profile::params::rgw_keystone_admin_domain,
  $rgw_keystone_admin_project       = $::ceph::profile::params::rgw_keystone_admin_project,
  $rgw_keystone_admin_user          = $::ceph::profile::params::rgw_keystone_admin_user,
  $rgw_keystone_admin_password      = $::ceph::profile::params::rgw_keystone_admin_password,
  $rgw_keystone_implicit_tenants    = true,
) {

  unless $name =~ /^radosgw\..+/ {
    fail("Define name must be started with 'radosgw.'")
  }

  ceph_config {
    "client.${name}/rgw_keystone_url":                 value => $rgw_keystone_url;
    "client.${name}/rgw_keystone_accepted_roles":      value => join(any2array($rgw_keystone_accepted_roles), ',');
    "client.${name}/rgw_keystone_token_cache_size":    value => $rgw_keystone_token_cache_size;
    "client.${name}/rgw_s3_auth_use_keystone":         value => $rgw_s3_auth_use_keystone;
    "client.${name}/rgw_keystone_implicit_tenants":    value => $rgw_keystone_implicit_tenants;
  }

  if $rgw_keystone_version == 'v2.0' {
    if $rgw_keystone_admin_token == undef
    {
      fail( 'Missing rgw_keystone_admin_token for Keystone V2 integration')
    }
    ceph_config {
      "client.${name}/rgw_keystone_admin_token": value => $rgw_keystone_admin_token;
    }
  } elsif $rgw_keystone_version == 'v3' {
    if $rgw_keystone_admin_domain == undef
      or $rgw_keystone_admin_project == undef
      or $rgw_keystone_admin_user == undef
      or $rgw_keystone_admin_password == undef
    {
      fail( 'Incomplete parameters for Keystone V3 integration')
    }
    ceph_config {
      "client.${name}/rgw_keystone_api_version":    value => 3;
      "client.${name}/rgw_keystone_admin_domain":   value => $rgw_keystone_admin_domain;
      "client.${name}/rgw_keystone_admin_project":  value => $rgw_keystone_admin_project;
      "client.${name}/rgw_keystone_admin_user":     value => $rgw_keystone_admin_user;
      "client.${name}/rgw_keystone_admin_password": value => $rgw_keystone_admin_password;
      "client.${name}/rgw_keystone_admin_token":    ensure => absent;
    }

  } else {
    fail("Unsupported keystone version: ${rgw_keystone_version}")
  }

  if $use_pki {
    # fetch the keystone signing cert, add to nss db
    $pkg_nsstools = $::ceph::params::pkg_nsstools
    ensure_packages($pkg_nsstools, {'ensure' => 'present'})

    file { $nss_db_path:
      ensure => directory,
      owner  => $user,
      group  => 'root',
    }

    ceph_config {
      "client.${name}/nss_db_path":                      value => $nss_db_path;
      "client.${name}/rgw_keystone_revocation_interval": value => $rgw_keystone_revocation_interval;
    }

    exec { "${name}-nssdb-ca":
      command => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate ${rgw_keystone_url}/v2.0/certificates/ca -O - |
  openssl x509 -pubkey | certutil -A -d ${nss_db_path} -n ca -t \"TCu,Cu,Tuw\"
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
wget --no-check-certificate ${rgw_keystone_url}/v2.0/certificates/signing -O - |
  openssl x509 -pubkey | certutil -A -d ${nss_db_path} -n signing_cert -t \"P,P,P\"
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
    ~> Service<| tag == 'ceph-radosgw' |>
  } else {
    ceph_config {
      "client.${name}/nss_db_path":                      ensure => absent;
      "client.${name}/rgw_keystone_revocation_interval": value => $rgw_keystone_revocation_interval;
    }
  }
}
