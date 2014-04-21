Use Cases
=========

I want to try this module, heard of ceph, want to see it in action
------------------------------------------------------------------

I want to run it on a virtual machine, all in one. The **ceph::conf** class will create configuration file with no authentication enabled. The **ceph::mon** resource configures and runs a monitor to which two **ceph::osd** daemon will connect to provide disk storage, using two disks attached to the virtual machine.

    class { 'ceph::conf':
      fsid        => generate('/usr/bin/uuidgen'),
      mon_host    => $::ipaddress_eth0,
      authentication_type => 'none',
    }
    ceph::mon { 'a':
      public_addr => $::ipaddress_eth0,
      osd_pool_default_size => 1,
      authentication_type => 'none',
    };
    ceph::osd { '/dev/vdb': };

* install puppet and this module,
* paste the snippet above in /tmp/ceph.puppet,
* puppet apply /tmp/ceph.puppet,
* type **ceph -s** : it will connect to the monitor and report that the cluster is ready to be used.

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

I want to spawn a cluster configured with a puppetmaster as part of a continuous integration effort
---------------------------------------

Leveraging vagrant, vagrant-openstack, openstack

Ceph is used as a backend storage for various use cases
There are tests to make sure the Ceph cluster was instantiated properly
There are tests to make sure various other infrastructure components (or products) can use the Ceph cluster

I want to run benchmarks on three new machines
-----------------------------------------------

There are four machines, 3 OSD, 1 MON and one machine that is the client from which the user runs commands.
install puppetmaster and create site.pp with:

    /ceph-default/ {
     class { 'ceph::conf':
        auth_enable => false,
        mon_host    => 'node1'
      };
    }

    /node1/ inherits ceph-default {
     ceph::mon { $hostname: };
     ceph::osd { 'discover': };
    }

    /node2/, /node3/ inherits ceph-default {
     ceph::osd { 'discover': };
    }

    /client/ inherits ceph-default {
    class { 'ceph::client' };
    }

* ssh client
* rados bench
* interpret the results
