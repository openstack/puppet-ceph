class ceph::profile::base {
  $fsid = hiera('ceph::conf::fsid')
  $authentication_type = hiera('ceph::conf::authentication_type')
  $osd_pool_default_pg_num = hiera('ceph::conf::osd_pool_default_pg_num')
  $osd_pool_default_pgp_num = hiera('ceph::conf::osd_pool_default_pgp_num')
  $osd_pool_size = hiera('ceph::conf::osd_pool_default_size')
  $osd_pool_default_min_size = hiera('ceph::conf::osd_pool_default_min_size')
  $mon_initial_members = hiera('ceph::conf::mon_initial_members')
  $mon_host = hiera('ceph::conf::mon_host')
  $cluster_network = hiera('ceph::conf::cluster_network')
  $public_network = hiera('ceph::conf::public_network')

  ceph { 'ceph':
    fsid                      => $fsid,
    authentication_type       => $authentication_type,
    osd_pool_default_pg_num   => $osd_pool_default_pg_num,
    osd_pool_default_pgp_num  => $osd_pool_default_pgp_num,
    osd_pool_size             => $osd_pool_size,
    osd_pool_default_min_size => $osd_pool_default_min_size,
    mon_initial_members       => $mon_initial_members,
    mon_host                  => $mon_host,
    cluster_network           => $cluster_network,
    public_network            => $public_network,
  }

}
