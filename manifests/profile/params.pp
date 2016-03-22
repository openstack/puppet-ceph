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
#  Author: David Moreau Simard <dmsimard@iweb.com>
#
# == Class: ceph::profile::params
#
# Extract the data from hiera where available
#
# === Parameters:
#
# [*fsid*] The cluster's fsid.
#   Mandatory. Get one with `uuidgen -r`.
#
# [*release*] The name of the Ceph release to install.
#   Optional.
#
# [*authentication_type*] Authentication type.
#   Optional. none or 'cephx'. Defaults to 'undef'.
#
# [*mon_initial_members*] The IDs of initial MONs in the cluster during startup.
#   Optional. String like e.g. 'a, b, c'.
#
# [*mon_host*] The fqdn of MONs in the cluster. They can also be declared
#   individually through ceph::mon.
#   Optional. String like e.g. 'a, b, c'.
#
# [*ms_bind_ipv6*] Enables Ceph daemons to bind to IPv6 addresses.
#   Optional. Boolean. Default provided by Ceph.
#
# [*osd_journal_size*] The size of the journal file/device.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_pg_num*] The default number of PGs per pool.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_pgp_num*] The default flags for new pools.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_size*] Number of replicas for objects in the pool
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_min_size*] The default minimum num of replicas.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_pool_default_crush_rule*] The default CRUSH ruleset to use
#   when creating a pool.
#   Optional. Integer. Default provided by Ceph.
#
# [*mon_osd_full_ratio*] Percentage of disk space used before
#   an OSD considered full
#   Optional. Integer e.g. 95, NOTE: ends in config as .95
#   Default provided by Ceph.
#
# [*mon_osd_nearfull_ratio*] Percentage of disk space used before
#   an OSD considered nearfull
#   Optional. Float e.g. 90, NOTE: ends in config as .90
#   Default provided by Ceph.
#
# [*cluster_network*] The address of the cluster network.
#   Optional. {cluster-network-ip/netmask}
#
# [*public_network*] The address of the public network.
#   Optional. {public-network-ip/netmask}
#
# [*public_addr*] The MON bind IP address.
#   Optional. The IPv(4|6) address on which MON binds itself.
#   This is useful when not specifying public_network or when there is more than one IP address on
#   the same network and you want to be specific about the IP to bind the MON on.
#
# [*mon_key*] The mon secret key.
#   Optional. Either mon_key or mon_keyring need to be set when using cephx.
#
# [*mon_keyring*] The location of the keyring retrieved by default
#   Optional. Either mon_key or mon_keyring need to be set when using cephx
#
# [*client_keys*] A hash of client keys that will be passed to ceph::keys.
#   Optional but required when using cephx.
#   See ceph::key for hash parameters andstructure.
#
# [*osds*] A Ceph osd hash
#   Optional.
#
# [*manage_repo*] Whether we should manage the local repository (true) or depend
#   on what is available (false). Set this to false when you want to manage the
#   the repo by yourself.
#   Optional. Defaults to true
#
# [*rgw_name*] the name for the radosgw cluster. Must be in the format
#  "radosgw.${name}" where name is whatever you want
#   Optional.
#
# [*rgw_user*] the user ID radosgw should run as.
#   Optional.
#
# [*rgw_print_continue*] should http 100 continue be used
#  Optional.
#
# [*frontend_type*] What type of frontend to use
#   Optional. Options are apache-fastcgi, apache-proxy-fcgi or civetweb
#
# [*rgw_frontends*] Arguments to the rgw frontend
#   Optional. Example: "civetweb port=7480"
#

class ceph::profile::params (
  $fsid = undef,
  $release = undef,
  $authentication_type = undef,
  $mon_initial_members = undef,
  $mon_host = undef,
  $ms_bind_ipv6 = undef,
  $osd_journal_size = undef,
  $osd_pool_default_pg_num = undef,
  $osd_pool_default_pgp_num = undef,
  $osd_pool_default_size = undef,
  $osd_pool_default_min_size = undef,
  $cluster_network = undef,
  $public_network = undef,
  $public_addr = undef,
  $mon_key = undef,
  $mon_keyring = undef,
  $client_keys = {},
  $osds = undef,
  $manage_repo = true,
  $rgw_name = undef,
  $rgw_user = undef,
  $rgw_print_continue = undef,
  $frontend_type = undef,
  $rgw_frontends = undef,
) {
  validate_hash($client_keys)

  if $authentication_type == 'cephx' and empty($client_keys) {
    fail("client_keys must be provided when using authentication_type = 'cephx'")
  }
}
