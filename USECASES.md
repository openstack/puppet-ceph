I want to operate a production cluster
---------------------------------------

_Notice : Please note that the code below is a sample which may not be up to date and is not expected to work._

    $admin_key = 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
    $mon_key = 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
    $boostrap_osd_key = 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A=='

    /ceph-default/ {
       ceph::conf{
         mon_host => 'mon1.a.tld,mon2.a.tld.com,mon3.a.tld'
       };
    }

    /mon[123]/ inherits ceph-default {
      ceph::mon{ $hostname: key => $mon_key }
      ceph::key{'client.admin':
          secret => $admin_key,
          caps_mon => '*',
          caps_osd => '*',
          inject => true,
      }
      cceph::key{'client.bootstrap-osd':
          secret => $bootstrap_osd_key,
          caps_mon => 'profile bootstrap-osd'
          inject => true,
      }
    }

    /osd*/ inherits ceph-default {
      ceph::osd{ 'discover' };
      ceph::key{'client.bootstrap-osd':
         keyring => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
         secret => $bootstrap_osd_key,
      }
    }

    /client/ inherits ceph-default {
       ceph::key{'client.admin':
         keyring => '/etc/ceph/ceph.client.admin.keyring',
         secret => $admin_key
       }
       ceph::client{ };
    }

* the *osd* nodes only contain disks that are used for OSD and using the discover option to automatically use new disks and provision them as part of the cluster is acceptable, there is no risk of destroying unrelated data.
* when a hardware is decomissioned, all its disks can be placed in another machines and the OSDs will automatically be re-inserted in the cluster, even if an external journal is used
