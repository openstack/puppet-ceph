class ceph::profile::rgw {
  require ::ceph::profile::base

  if $ceph::profile::params::enable_rgw
  {
    ceph::rgw { "radosgw.gateway":
      user => $ceph::profile::params::rgw_user,
      rgw_frontends => $ceph::profile::params::rgw_frontends ,
      frontend_type => $ceph::profile::params::frontend_type ,
    }
   
  }

}
