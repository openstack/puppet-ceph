#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
#
# == Class: ceph
#
# init takes care of installing/configuring the common dependencies across classes
# it also takes care of the global configuration values
#
# === Parameters:
#
# [*fsid*] The cluster's fsid.
#   Mandatory. Get one with `uuidgen -r`.
#
# [*ensure*] Installs ( present ) or removes ( absent ) ceph.
#   Optional. Defaults to present.
#
# [*authentication_type*] Authentication type.
#   Optional. none or 'cephx'. Defaults to 'cephx'.
#
# [*keyring*] The location of the keyring retrieved by default
#   Optional. Defaults to /etc/ceph/keyring.
#
# [*osd_journal_size*] The size of the journal file/device.
#   Optional. Integer. Default provided by Ceph.
#
# [*osd_max_object_name_len*] The length of the objects name
#   Optional. Integer. Default to undef
#
# [*osd_max_object_namespace_len*] The length of the objects namespace name
#   Optional. Integer. Default to undef
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
# [*osd_crush_update_on_start*] The default OSDs behaviour on start when
#   it comes to registering their location in the CRUSH map.
#   Optional. Boolean. Defaults to undef.
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
# [*require_signatures*] If Ceph requires signatures on all
#   message traffic (client<->cluster and between cluster daemons).
#   Optional. Boolean. Default provided by Ceph.
#
# [*cluster_require_signatures*] If Ceph requires signatures on all
#   message traffic between the cluster daemons.
#   Optional. Boolean. Default provided by Ceph.
#
# [*service_require_signatures*] If Ceph requires signatures on all
#   message traffic between clients and the cluster.
#   Optional. Boolean. Default provided by Ceph.
#
# [*sign_messages*] If all ceph messages should be signed.
#   Optional. Boolean. Default provided by Ceph.
#
# [*cluster_network*] The address of the cluster network.
#   Optional. {cluster-network-ip/netmask}
#
# [*public_network*] The address of the public network.
#   Optional. {public-network-ip/netmask}
#
# [*public_addr*] The address of the node (on public network.)
#   Optional. {public-network-ip}
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
# [*rbd_default_features*] Set RBD features configuration.
#   Optional. String. Defaults to undef.
#
# DEPRECATED PARAMETERS
#
# [*set_osd_params*] disables setting osd params using this module by default as people
#   calling ceph_config from in-house modules will get dup-declaration errors.
#   Boolean.  Default false.
#

class ceph (
  $fsid,
  $ensure                        = present,
  $authentication_type           = 'cephx',
  $keyring                       = undef,
  $osd_journal_size              = undef,
  $osd_max_object_name_len       = undef,
  $osd_max_object_namespace_len  = undef,
  $osd_pool_default_pg_num       = undef,
  $osd_pool_default_pgp_num      = undef,
  $osd_pool_default_size         = undef,
  $osd_pool_default_min_size     = undef,
  $osd_pool_default_crush_rule   = undef,
  $osd_crush_update_on_start     = undef,
  $mon_osd_full_ratio            = undef,
  $mon_osd_nearfull_ratio        = undef,
  $mon_initial_members           = undef,
  $mon_host                      = undef,
  $ms_bind_ipv6                  = undef,
  $require_signatures            = undef,
  $cluster_require_signatures    = undef,
  $service_require_signatures    = undef,
  $sign_messages                 = undef,
  $cluster_network               = undef,
  $public_network                = undef,
  $public_addr                   = undef,
  $osd_max_backfills             = undef,
  $osd_recovery_max_active       = undef,
  $osd_recovery_op_priority      = undef,
  $osd_recovery_max_single_start = undef,
  $osd_max_scrubs                = undef,
  $osd_op_threads                = undef,
  $rbd_default_features          = undef,
  # DEPRECATED PARAMETERS
  $set_osd_params                = false,
) {
  include ::ceph::params

  if $set_osd_params {
    warning('set_osd_params is deprecated. It is here to allow a transition to using \
this module to assign values and will be removed in a future release.')
  }

  package { $::ceph::params::packages :
    ensure => $ensure,
    tag    => 'ceph'
  }

  if $ensure !~ /(absent|purged)/ {
    # Make sure ceph is installed before managing the configuration
    Package<| tag == 'ceph' |> -> Ceph_config<| |>
    # [global]
    ceph_config {
      'global/fsid':                         value => $fsid;
      'global/keyring':                      value => $keyring;
      'global/osd_pool_default_pg_num':      value => $osd_pool_default_pg_num;
      'global/osd_pool_default_pgp_num':     value => $osd_pool_default_pgp_num;
      'global/osd_pool_default_size':        value => $osd_pool_default_size;
      'global/osd_pool_default_min_size':    value => $osd_pool_default_min_size;
      'global/osd_pool_default_crush_rule':  value => $osd_pool_default_crush_rule;
      'global/osd_crush_update_on_start':    value => $osd_crush_update_on_start;
      'global/mon_osd_full_ratio':           value => $mon_osd_full_ratio;
      'global/mon_osd_nearfull_ratio':       value => $mon_osd_nearfull_ratio;
      'global/mon_initial_members':          value => $mon_initial_members;
      'global/mon_host':                     value => $mon_host;
      'global/ms_bind_ipv6':                 value => $ms_bind_ipv6;
      'global/require_signatures':           value => $require_signatures;
      'global/cluster_require_signatures':   value => $cluster_require_signatures;
      'global/service_require_signatures':   value => $service_require_signatures;
      'global/sign_messages':                value => $sign_messages;
      'global/cluster_network':              value => $cluster_network;
      'global/public_network':               value => $public_network;
      'global/public_addr':                  value => $public_addr;
      'osd/osd_journal_size':                value => $osd_journal_size;
      'client/rbd_default_features':         value => $rbd_default_features;
    }


    # NOTE(aschultz): for backwards compatibility in p-o-i & elsewhere we only
    # define these here if they are set. Once this patch lands, we can update
    # p-o-i to leverage these parameters and ditch these if clauses.
    if $osd_max_object_name_len {
      ceph_config {
        'global/osd_max_object_name_len':      value => $osd_max_object_name_len;
      }
    }
    if $osd_max_object_namespace_len {
      ceph_config {
        'global/osd_max_object_namespace_len': value => $osd_max_object_namespace_len;
      }
    }

    if $authentication_type == 'cephx' {
      ceph_config {
        'global/auth_cluster_required': value => 'cephx';
        'global/auth_service_required': value => 'cephx';
        'global/auth_client_required':  value => 'cephx';
        'global/auth_supported':        value => 'cephx';
      }
    } else {
      ceph_config {
        'global/auth_cluster_required': value => 'none';
        'global/auth_service_required': value => 'none';
        'global/auth_client_required':  value => 'none';
        'global/auth_supported':        value => 'none';
      }
    }

# This section will be moved up with the rest of the non-auth settings in the next release and the set_osd_params flag will be removed
    if $set_osd_params {
      ceph_config {
        'osd/osd_max_backfills':             value => $osd_max_backfills;
        'osd/osd_recovery_max_active':       value => $osd_recovery_max_active;
        'osd/osd_recovery_op_priority':      value => $osd_recovery_op_priority;
        'osd/osd_recovery_max_single_start': value => $osd_recovery_max_single_start;
        'osd/osd_max_scrubs':                value => $osd_max_scrubs;
        'osd/osd_op_threads':                value => $osd_op_threads;
      }
    }
  }
}
