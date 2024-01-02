# == Class: ceph::rgw::keystone::auth
#
# Configures RGW user, service and endpoint in Keystone V3.
#
# === Parameters
#
# [*password*]
#   Password for the RGW user. Required.
#
# [*user*]
#   Username for the RGW user. Required.
#
# [*tenant*]
#   Tenant for user. Required.
#
# [*email*]
#   Email for the RGW user. Optional.
#   Defaults to 'rgwuser@localhost'
#
# [*roles*]
#   Accepted RGW roles. Optional.
#   Defaults to ['admin']
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
# [*service_description*]
#   (Optional) Description of the service.
#   Default to 'Ceph RGW Service'
#
# [*service_name*]
#   (Optional) Name of the service.
#   Defaults to 'swift'.
#
# [*service_type*]
#   (Optional) Type of service.
#   Defaults to 'object-store'.
#
class ceph::rgw::keystone::auth (
  $password,
  $user,
  $tenant,
  $email               = 'rgwuser@localhost',
  $roles               = ['admin'],
  $public_url          = 'http://127.0.0.1:8080/swift/v1',
  $admin_url           = 'http://127.0.0.1:8080/swift/v1',
  $internal_url        = 'http://127.0.0.1:8080/swift/v1',
  $region              = 'RegionOne',
  $service_description = 'Ceph RGW Service',
  $service_name        = 'swift',
  $service_type        = 'object-store',
) {

  include openstacklib::openstackclient

  ensure_resource('keystone_service', "${service_name}::${service_type}", {
    'ensure'      => 'present',
    'description' => $service_description,
  } )

  ensure_resource('keystone_endpoint', "${region}/${service_name}::${service_type}", {
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

