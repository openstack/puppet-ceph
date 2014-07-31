#
#  Copyright (C) 2014 Nine Internet Solutions AG
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
#  Author: David Gurtner <aldavud@crimson.ch>
#
# Extract the data from hiera where available
#
class ceph::profile::params (
  # puppet 2.7 compatibiliy hack. TODO: change to undef once 2.7 is deprecated
  $fsid = '4b5c8c0a-ff60-454b-a1b4-9747aa737d19',
  $release = undef,
  $authentication_type = undef,
  $mon_initial_members = undef,
  $mon_host = undef,
  $osd_pool_default_pg_num = undef,
  $osd_pool_default_pgp_num = undef,
  $osd_pool_default_size = undef,
  $osd_pool_default_min_size = undef,
  $cluster_network = undef,
  $public_network = undef,
  $admin_key = undef,
  $admin_key_mode = undef,
  $mon_key = undef,
  $mon_keyring = undef,
  $bootstrap_osd_key = undef,
  $bootstrap_mds_key = undef,
  $osds = undef,
) {
}
