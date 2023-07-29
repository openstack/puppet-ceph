#
#  Copyright (C) 2016 Keith Schincke
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
# Author: Keith Schincke <keith.schincke@gmail.com>
#
# == Class: ceph::profile::rgw
#
# Profile for Ceph rgw
#
class ceph::profile::rgw {
  require ceph::profile::base
  $rgw_name = $ceph::profile::params::rgw_name ? {
    undef   => 'radosgw.gateway',
    default => $ceph::profile::params::rgw_name,
  }
  ceph::rgw { $rgw_name:
    user               => $ceph::profile::params::rgw_user,
    rgw_print_continue => $ceph::profile::params::rgw_print_continue,
    frontend_type      => $ceph::profile::params::frontend_type,
    rgw_frontends      => $ceph::profile::params::rgw_frontends,
    rgw_swift_url      => $ceph::profile::params::rgw_swift_url,
  }

  if $ceph::profile::params::rgw_keystone_integration {
    ceph::rgw::keystone { $rgw_name:
      rgw_keystone_admin_domain   => $ceph::profile::params::rgw_keystone_admin_domain,
      rgw_keystone_admin_project  => $ceph::profile::params::rgw_keystone_admin_project,
      rgw_keystone_admin_user     => $ceph::profile::params::rgw_keystone_admin_user,
      rgw_keystone_admin_password => $ceph::profile::params::rgw_keystone_admin_password,
      rgw_keystone_url            => $ceph::profile::params::rgw_keystone_url,
    }

    class { 'ceph::rgw::keystone::auth':
      password     => $ceph::profile::params::rgw_keystone_admin_password,
      user         => $ceph::profile::params::rgw_keystone_admin_user,
      tenant       => $ceph::profile::params::rgw_keystone_admin_project,
      public_url   => $ceph::profile::params::rgw_swift_public_url,
      admin_url    => $ceph::profile::params::rgw_swift_admin_url,
      internal_url => $ceph::profile::params::rgw_swift_internal_url,
      region       => $ceph::profile::params::rgw_swift_region,
    }
  }
}
