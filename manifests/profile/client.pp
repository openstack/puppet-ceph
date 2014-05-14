#
#   Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: David Gurtner <david@nine.ch>
#
# Profile for a Ceph client
#
class ceph::profile::client inherits ceph::profile::base {
  $admin_key = hiera('ceph::key::admin')

  # we need the mons before we can define clients
  Ceph::Profile::Mon<| |> -> Ceph::Profile::Client<| |>

  # if this is also a mon, the key is already defined
  if ! defined(Ceph::Key['client.admin']) {
    ceph::key { 'client.admin':
      keyring_path => '/etc/ceph/ceph.client.admin.keyring',
      secret       => $admin_key,
    }
  }
}
