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

  Keystone::Resource::Service_identity['rgw'] -> Service<| tag == 'ceph-radosgw' |>

  keystone::resource::service_identity { 'rgw':
    configure_user      => true,
    configure_user_role => true,
    configure_endpoint  => true,
    service_name        => $service_name,
    service_type        => $service_type,
    service_description => $service_description,
    region              => $region,
    auth_name           => $user,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    roles               => $roles,
    public_url          => $public_url,
    internal_url        => $internal_url,
    admin_url           => $admin_url,
  }
}
