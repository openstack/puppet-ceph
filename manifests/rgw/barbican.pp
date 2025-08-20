#
#  Copyright (C) 2022 Red Hat
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
# Author: Takashi Kajinami <tkajinam@redhat.com>
#
# == Define: ceph::rgw::barbican
#
# Configures Barbican integration of the ceph radosgw
#
### == Name
# # The RGW id. An alphanumeric string uniquely identifying the RGW.
# ( example: radosgw.gateway )
#
### == Parameters
#
# [*rgw_keystone_barbican_domain*]
#   (Required) The name of the OpenStack domain associated with the Barbican
#   user when using OpenStack Identity API v3.
#
# [*rgw_keystone_barbican_project*]
#   (Required) The name of the OpenStack tenant associated with the Barbican
#   user when using OpenStack Identity API v3
#
# [*rgw_keystone_barbican_user*]
#   (Required) The name of the OpenStack user with access to the Barbican
#   secrets used for Encryption.
#
# [*rgw_keystone_barbican_password*]
#   (Required) The password associated with the Barbican user.
#
# [*rgw_barbican_url*]
#   (Optional) URL for the Barbican server.
#   Defaults to 'http://127.0.0.1:9311'.
#
define ceph::rgw::barbican (
  $rgw_keystone_barbican_domain,
  $rgw_keystone_barbican_project,
  $rgw_keystone_barbican_user,
  $rgw_keystone_barbican_password,
  $rgw_barbican_url               = 'http://127.0.0.1:9311',
) {
  unless $name =~ /^radosgw\..+/ {
    fail("Define name must be started with 'radosgw.'")
  }

  ceph_config {
    "client.${name}/rgw_keystone_barbican_domain":   value => $rgw_keystone_barbican_domain;
    "client.${name}/rgw_keystone_barbican_project":  value => $rgw_keystone_barbican_project;
    "client.${name}/rgw_keystone_barbican_user":     value => $rgw_keystone_barbican_user;
    "client.${name}/rgw_keystone_barbican_password": value => $rgw_keystone_barbican_password, secret => true;
    "client.${name}/rgw_barbican_url":               value => $rgw_barbican_url;
  }
}
