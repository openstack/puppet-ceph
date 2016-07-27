# == Class: ceph::rgw::keystone::auth
#
# Configures RGW user, service and endpoint in Keystone V3.
#
# === Parameters
#
# [*password*]
#  Password for the RGW user. Required
#
# [*user*]
#   Username for the RGW user. Optional.
#   Defaults to 'rgwuser'
#
# [*email*]
#   Email for the RGW user. Optional.
#   Defaults to 'rgwuser@localhost'
#
# [*roles*]
#   Accepted RGW roles. Optional.
#   Defaults to ['admin', 'Member']
#
# [*public_url*]
#   The public URL. Optional.
#   Defaults to 'http://127.0.0.1:8080/swift/v1
#
# [*admin_url*]
#   The admin URL. Optional.
#   Defaults to 'http://127.0.0.1:8080/swift/v1
#
# [*internal_url*]
#   The internal URL. Optional.
#   Defaults to 'http://127.0.0.1:8080/swift/v1
#
# [*region*]
#   Region for endpoint. Optional.
#   Defaults to 'RegionOne'
#
# [*tenant*]
#   Tenant for user. Optional.
#   Defaults to 'services'
#
# [*rgw_service*]
#   Name of the keystone service used by RGW
#   Defaults to 'swift::object-store'
#

class ceph::rgw::keystone::auth (
  $password,
  $user         = 'rgwuser',
  $email        = 'rgwuser@localhost',
  $roles        = ['admin', 'Member'],
  $public_url   = 'http://127.0.0.1:8080/swift/v1',
  $admin_url    = 'http://127.0.0.1:8080/swift/v1',
  $internal_url = 'http://127.0.0.1:8080/swift/v1',
  $region       = 'RegionOne',
  $tenant       = 'services',
  $rgw_service  = 'swift::object-store',
) {

  include ::openstacklib::openstackclient

  ensure_resource('keystone_service', 'swift::object-store', {
    'ensure'      => 'present',
    'description' => 'Ceph RGW Service',
  } )

  ensure_resource('keystone_endpoint', "${region}/swift::object-store", {
    'ensure'       => 'present',
    'public_url'   => $public_url,
    'admin_url'    => $admin_url,
    'internal_url' => $internal_url,
  } )

  keystone_user { $user:
    ensure   => present,
    password => $password,
    email    => $email,
  }

  ensure_resource('keystone_role', $roles, {
    'ensure' => 'present'
  } )

  keystone_user_role { "${user}@${tenant}":
    ensure => present,
    roles  => $roles,
  }
}

