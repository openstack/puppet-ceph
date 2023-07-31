# == Class: ceph::rgw::keystone::auth
#
# Configures RGW user, service and endpoint in Keystone V3.
#
# === Parameters
#
# [*password*]
#  Password for the RGW user. 
#  Defaults to ceph::profile::params::rgw_keystone_admin_password
#
# [*user*]
#   Username for the RGW user. Optional.
#   Defaults to ceph::profile::params::rgw_keystone_admin_use
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
# [*tenant*]
#   Tenant for user. Optional.
#   Defaults to ceph::profile::params::rgw_keystone_admin_project
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
# DEPRECATED PARAMETERS
#
# [*rgw_service*]
#   Name of the keystone service used by RGW
#   Defaults to undef
#
class ceph::rgw::keystone::auth (
  $password            = $ceph::profile::params::rgw_keystone_admin_password,
  $user                = $ceph::profile::params::rgw_keystone_admin_user,
  $email               = 'rgwuser@localhost',
  $roles               = ['admin'],
  $public_url          = 'http://127.0.0.1:8080/swift/v1',
  $admin_url           = 'http://127.0.0.1:8080/swift/v1',
  $internal_url        = 'http://127.0.0.1:8080/swift/v1',
  $region              = 'RegionOne',
  $tenant              = $ceph::profile::params::rgw_keystone_admin_project,
  $service_description = 'Ceph RGW Service',
  $service_name        = 'swift',
  $service_type        = 'object-store',
  # DEPRECATED PARAMETERS
  $rgw_service         = undef,
) {

  include openstacklib::openstackclient

  if $rgw_service {
    warning('The rgw_service parameter is deprecated')
    $rgw_service_real = $rgw_service
  } else {
    $rgw_service_real = "${service_name}::${service_type}"
  }

  ensure_resource('keystone_service', $rgw_service_real, {
    'ensure'      => 'present',
    'description' => $service_description,
  } )

  ensure_resource('keystone_endpoint', "${region}/${rgw_service_real}", {
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

