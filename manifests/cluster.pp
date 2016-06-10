define ceph::cluster (
  $cluster                    = "$name",
  $fsid,
  $ensure                     = present,
  $authentication_type        = 'cephx',
  $keyring                    = undef,
  $osd_journal_size           = undef,
  $osd_pool_default_pg_num    = undef,
  $osd_pool_default_pgp_num   = undef,
  $osd_pool_default_size      = undef,
  $osd_pool_default_min_size  = undef,
  $osd_pool_default_crush_rule= undef,
  $osd_crush_location         = undef,
  $osd_crush_chooseleaf_type  = undef,
  $osd_op_thread_timeout      = undef,
  $osd_recovery_thread_timeout = undef,
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
  $cluster_network            = undef,
  $public_network             = undef,
  $public_addr                = undef,
) {
 
    # [global]
    ceph_config {
      "$cluster/global/fsid":                        value => $fsid;
      "$cluster/global/keyring":                     value => $keyring;
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
      "$cluster/global/cluster_network":             value => $cluster_network;
      "$cluster/global/public_network":              value => $public_network;
      "$cluster/global/public_addr":                 value => $public_addr;
      "$cluster/osd/osd_journal_size":               value => $osd_journal_size;
      "$cluster/osd/osd_crush_location":             value => $osd_crush_location;
      "$cluster/osd/osd_op_thread_timeout":          value => $osd_op_thread_timeout;
      "$cluster/osd/osd_recovery_thread_timeout":    value => $osd_recovery_thread_timeout;

    }

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