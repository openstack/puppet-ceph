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
# [*ms_bind_ipv4*] Enables Ceph daemons to bind to IPv4 addresses.
#   Optional. Boolean. Default provided by Ceph.
#
# [*ms_bind_ipv6*] Enables Ceph daemons to bind to IPv6 addresses.
#   Optional. Boolean. Default provided by Ceph.
#
# [*osd_journal_size*] The size of the journal file/device.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_max_object_name_len*] The maximum length of a rados object name
#   Optional. Integer. Default to undef.
#
# [*osd_max_object_namespace_len*] The maximum length of a rados object name
#   Optional. Integer. Default to undef.
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
# [*osd_crush_update_on_start*] The default OSDs behaviour on start when
#   it comes to registering their location in the CRUSH map.
#   Optional. Boolean. Defaults to undef.
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
# [*mds_key*] The mds secret key.
#   Optional but required when using cephx.
#
# [*mon_key*] The mon secret key.
#   Optional. Either mon_key or mon_keyring need to be set when using cephx.
#
# [*mgr_key*] The mgr secret key.
#   Optional. Either mgr_key or mgr_keyring need to be set when using cephx.
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
#   Optional. Options are civetweb, beast and apache-proxy-fcgi
#
# [*rgw_frontends*] Arguments to the rgw frontend
#   Optional. Example: "civetweb port=7480"
#
# [*rgw_swift_url*] The URL for the Ceph Object Gateway Swift API.
#   Optional.
#
# [*osd_max_backfills*] The maximum number of backfills allowed to or from a single OSD.
#   Optional. Default provided by Ceph
#
# [*osd_recovery_max_active*] The number of active recovery requests per OSD at one time.
#   Optional.  Default provided by Ceph
#
# [*osd_recovery_op_priority*] The priority set for recovery operations.
#   Optional.  Default provided by Ceph
#
# [*osd_recovery_max_single_start*] The maximum number of recovery operations that will be
#   newly started per PG that the OSD is recovering.
#   Optional.  Default provided by Ceph
#
# [*osd_max_scrubs*] The maximum number of simultaneous scrub operations for a Ceph OSD Daemon.
#   Optional.  Default provided by Ceph
#
# [*osd_op_threads*] The number of threads to service Ceph OSD Daemon operations.
#   Set to 0 to disable it.
#   Optional. Default provided by Ceph
#
# [*rgw_keystone_integration*] Enables RGW integration with OpenStack Keystone
#   Optional. Default is false
#
# [*rgw_keystone_url*] The internal or admin url for keystone.
#   Optional. Default is undef
#
# [*rgw_keystone_admin_domain*] The name of OpenStack domain with admin privilege.
#   Optional. Default is undef
#
# [*rgw_keystone_admin_project*] The name of OpenStack project with admin privilege.
#   Required when RGW integration with Keystone is enabled.
#
# [*rgw_keystone_admin_user*] The user name of OpenStack tenant with admin privilege.
#   Required when RGW integration with Keystone is enabled.
#
# [*rgw_keystone_admin_password*] The password for OpenStack admin user
#   Required when RGW integration with Keystone is enabled.
#
# [*rgw_swift_public_url*] The public URL of Swift API. Optional.
#
# [*rgw_swift_admin_url*] The admin URL of Swift API. Optional.
#
# [*rgw_swift_internal_url*] The internal URL of Swift API. Optional.
#
# [*rgw_swift_region*] The region for Swift API. Optional
#
# [*rbd_mirror_client_name*] Name of the cephx client key used for rbd mirroring
#   Optional. Default is undef
#
# [*fs_name*] The FS name.
#   Optional but required when using fs.
#
# [*fs_metadata_pool*] The FS metadata pool name.
#   Optional but required when using fs.
#
# [*fs_data_pool*] The FS data pool name.
#   Optional but required when using fs.
#
# [*rbd_default_features*] Set RBD features configuration.
#   Optional. String. Defaults to undef.
#
# **DEPRECATED PARAMS**
#
# [*pid_max*] Value for pid_max. Defaults to undef. Optional.
#   For OSD nodes it is recommended that you raise pid_max above the
#   default value because you may hit the system max during
#   recovery. The recommended value is the absolute max for pid_max: 4194303
#   http://docs.ceph.com/docs/nautilus/rados/troubleshooting/troubleshooting-osd/
#
class ceph::profile::params (
  $fsid = undef,
  $release = undef,
  Optional[Enum['cephx', 'none']] $authentication_type = undef,
  $mon_initial_members = undef,
  $mon_host = undef,
  $ms_bind_ipv4 = undef,
  $ms_bind_ipv6 = undef,
  $osd_journal_size = undef,
  $osd_max_object_name_len = undef,
  $osd_max_object_namespace_len = undef,
  $osd_pool_default_pg_num = undef,
  $osd_pool_default_pgp_num = undef,
  $osd_pool_default_size = undef,
  $osd_pool_default_min_size = undef,
  $osd_crush_update_on_start = undef,
  $cluster_network = undef,
  $public_network = undef,
  $public_addr = undef,
  $mds_key = undef,
  $mon_key = undef,
  $mgr_key = undef,
  $mon_keyring = undef,
  Hash $client_keys = {},
  $osds = undef,
  Boolean $manage_repo = true,
  $rgw_name = undef,
  $rgw_user = undef,
  $rgw_print_continue = undef,
  $frontend_type = undef,
  $rgw_frontends = undef,
  $rgw_swift_url = undef,
  $osd_max_backfills = undef,
  $osd_recovery_max_active = undef,
  $osd_recovery_op_priority = undef,
  $osd_recovery_max_single_start = undef,
  $osd_max_scrubs = undef,
  $osd_op_threads = undef,
  Boolean $rgw_keystone_integration = false,
  $rgw_keystone_url = undef,
  $rgw_keystone_admin_domain = undef,
  $rgw_keystone_admin_project = undef,
  $rgw_keystone_admin_user = undef,
  $rgw_keystone_admin_password = undef,
  $rgw_swift_public_url = undef,
  $rgw_swift_admin_url = undef,
  $rgw_swift_internal_url = undef,
  $rgw_swift_region = undef,
  $rbd_mirror_client_name = undef,
  $fs_metadata_pool = undef,
  $fs_data_pool = undef,
  $fs_name = undef,
  $rbd_default_features = undef,
  # DEPRECATED PARAMS
  $pid_max = undef,
) {
  if $pid_max != undef {
    warning('pid_max parameter is deprecated and has no effect.')
  }

  if $authentication_type == 'cephx' and empty($client_keys) {
    fail("client_keys must be provided when using authentication_type = 'cephx'")
  }
}
