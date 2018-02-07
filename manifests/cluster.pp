
#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
#   Copyright (C) 2014 Nine Internet Solutions AG
#   Copyright (C) 2016 University of Michigan, funded by the NSF OSiRIS Project
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
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
# Author: Ben Meekhof <bmeekhof@umich.edu>

define ceph::cluster (
  $cluster                    = "$name",
  $fsid,
  $ensure                     = present,
  $authentication_type        = 'cephx',
  $keyring                    = undef,
  $debug_level                = 0,
  $osd_pool_default_pg_num    = undef,
  $osd_pool_default_pgp_num   = undef,
  $osd_pool_default_size      = undef,
  $osd_pool_default_min_size  = undef,
  $osd_pool_default_crush_rule= undef,
  $osd_crush_location         = undef, 
  $osd_crush_chooseleaf_type  = undef,
  $mon_osd_full_ratio         = undef,
  $mon_osd_nearfull_ratio     = undef,
  $rbd_default_features       = undef,
  $mon_initial_members        = undef,
  $mon_host                   = undef,
  $ms_bind_ipv6               = undef,
  $require_signatures         = undef,
  $cluster_require_signatures = undef,
  $service_require_signatures = undef,
  $sign_messages              = undef,
  $fuse_disable_pagecache     = true,
  $cluster_network            = undef,
  $public_network             = undef,
  $public_addr                = undef,
) {

    # [global]
    ceph_config {
      "$cluster/global/fsid":                        value => $fsid;
      "$cluster/global/keyring":                     value => $keyring;
      "$cluster/global/err_to_stderr":               value => false;   # if this is not set you end up with errors in syslog
      "$cluster/global/osd_pool_default_pg_num":     value => $osd_pool_default_pg_num;
      "$cluster/global/osd_pool_default_pgp_num":    value => $osd_pool_default_pgp_num;
      "$cluster/global/osd_pool_default_size":       value => $osd_pool_default_size;
      "$cluster/global/osd_pool_default_min_size":   value => $osd_pool_default_min_size;
      "$cluster/global/osd_pool_default_crush_rule": value => $osd_pool_default_crush_rule;
      "$cluster/global/osd_crush_chooseleaf_type":   value => $osd_crush_chooseleaf_type;
      "$cluster/global/mon_osd_full_ratio":          value => $mon_osd_full_ratio;
      "$cluster/global/mon_osd_nearfull_ratio":      value => $mon_osd_nearfull_ratio;
      "$cluster/global/rbd_default_features":        value => $rbd_default_features;
      "$cluster/global/mon_initial_members":         value => $mon_initial_members;
      "$cluster/global/mon_host":                    value => $mon_host;
      "$cluster/global/ms_bind_ipv6":                value => $ms_bind_ipv6;
      "$cluster/global/require_signatures":          value => $require_signatures;
      "$cluster/global/cluster_require_signatures":  value => $cluster_require_signatures;
      "$cluster/global/service_require_signatures":  value => $service_require_signatures;
      "$cluster/global/sign_messages":               value => $sign_messages;
      "$cluster/global/fuse_disable_pagecache":      value => $fuse_disable_pagecache;
      "$cluster/global/cluster_network":             value => $cluster_network;
      "$cluster/global/public_network":              value => $public_network;
      "$cluster/global/public_addr":                 value => $public_addr;
      "$cluster/osd/debug_filestore":                value => $debug_level;
      "$cluster/osd/debug_osd":                      value => $debug_level;
      "$cluster/osd/debug_journal":                  value => $debug_level;
      "$cluster/osd/debug_ms":                       value => $debug_level;
      "$cluster/osd/crush_location":                 value => $osd_crush_location; 
    }

    # bluestore_block_db_size - not setting because is per-osd setting determined by created LV size

    if $authentication_type == 'cephx' {
      ceph_config {
        "$cluster/global/auth_cluster_required": value => 'cephx';
        "$cluster/global/auth_service_required": value => 'cephx';
        "$cluster/global/auth_client_required":  value => 'cephx';
        "$cluster/global/auth_supported":        value => 'cephx';
      }
    } else {
      ceph_config {
        "$cluster/global/auth_cluster_required": value => 'none';
        "$cluster/global/auth_service_required": value => 'none';
        "$cluster/global/auth_client_required":  value => 'none';
        "$cluster/global/auth_supported":        value => 'none';
      }
    }
  }
