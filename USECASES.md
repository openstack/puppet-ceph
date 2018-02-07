Use Cases
=========

NOTE:  None of these are tested with current version of this module, but attempts have been made to update the samples with changes to the module.  

I want to try this module, heard of ceph, want to see it in action
------------------------------------------------------------------

I want to run it on a virtual machine, all in one. The **ceph::repo** class will enable the official ceph repository with the most current branch selected. The **ceph** class will create a configuration file with no authentication enabled. The **ceph::mon** resource configures and runs a monitor to which a **ceph::osd** daemon will connect to provide disk storage backed by the disk specified.  Using a directory is not supported by ceph-volume, but you could probably use a partition successfully (it will have a VG/LV hosted on top)

* install puppet and this module and its dependences (see metadata.json)
* paste the snippet above into /tmp/ceph.puppet
* `puppet apply /tmp/ceph.puppet`
* `ceph -s`: it will connect to the monitor and report that the cluster is ready to be used

```
    class { 'ceph': }
    
    ceph::cluster { 'ceph': 
      fsid                       => generate('/usr/bin/uuidgen'),
      mon_host                   => $::ipaddress,
      authentication_type        => 'none',
      osd_pool_default_size      => '1',
      osd_pool_default_min_size  => '1',
    }
    
    ceph::mon { 'a':
      public_addr         => $::ipaddress,
      authentication_type => 'none',
    }
    ceph::osd { '/dev/somedisk': }
```

I want to operate a production cluster
--------------------------------------

_Notice : Please note that the code below is a sample which is not expected to work without further configuration. You will need to at least adapt the hostnames, the IP addresses of the monitor hosts and the OSD disks to your setup._

On all machines:
* install puppet and this module and its dependences (see metadata.json)
* paste the snippet below into /tmp/ceph.puppet

On the monitor hosts:
* `puppet apply /tmp/ceph.puppet` (please note that you will need to run this on all monitor hosts at the same time, as they need to connect to each other to finish setting up)

On all other hosts:
* `puppet apply /tmp/ceph.puppet`

Enjoy your ceph cluster!

```
    $admin_key = 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
    $mon_key = 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
    $bootstrap_osd_key = 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A=='
    $fsid = '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'

    node /mon[123]/ {
    
      class { 'ceph': }
      
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_initial_members => 'mon1,mon2,mon3',
        mon_host            => '<ip of mon1>,<ip of mon2>,<ip of mon3>',
      }
      
      ceph::mon { $::hostname:
        key => $mon_key,
      }
      
      Ceph::Key {
        inject         => true,
        inject_as_id   => 'mon.',
        inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
      }
      
      ceph::key { 'client.admin':
        secret  => $admin_key,
        cap_mon => 'allow *',
        cap_osd => 'allow *',
        cap_mds => 'allow',
      }
      
       ceph::key { 'mds.mdskey':
        secret  => $mds_key,
    	cap_mon => 'allow profile mds'
        cap_osd => 'allow rwx'
        cap_mds => 'allow'
      }
      
      ceph::key { 'client.radosgw.rgw01':
        secret  => $rgw_key,
    	cap_mon => 'allow r',
	cap_osd => 'allow rwx'
      }
      
       ceph::key { 'client.bootstrap-osd':
        secret  => $bootstrap_osd_key,
        cap_mon => 'allow profile bootstrap-osd',
      }
    }
    

  }
  
  node /mds[123]/
      class { 'ceph': }
      
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_initial_members => 'mon1,mon2,mon3',
        mon_host            => '<ip of mon1>,<ip of mon2>,<ip of mon3>',
      }
      
      ceph::key { 'mds.mdskey':
        secret  => $mds_key,
	keyring_path => "/var/lib/ceph/mds/${cephx::cluster}-${::hostname}/keyring"
      }
     
      ceph::mds { "$::hostname": }
      
  }

    node /osd*/ {
      class { 'ceph': }
      
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_initial_members => 'mon1,mon2,mon3',
        mon_host            => '<ip of mon1>,<ip of mon2>,<ip of mon3>',
      }

      # this could also be an explicit size like 200M or 10G, etc
      # if not set then the default is to create an lv taking whole device
      Ceph::osd {
        db_size = "50%"
      }
      
      ceph::osd { 
        '<disk1>':
          db => '<db block device>';
        '<disk2>':
          db => '<db block device>';
      }

      # in the above usage the db block device should be a whole disk, like /dev/nvme0n1
      # OSD will be created with block.db pointing to LV on device, each LV taking 20% of device
      # Use param create_lv => false to skip creating LV...in this case pass logical volumes for disk and db block device (eg, vgdb/lv_name_db and vgdata/lv_name_data)

      ceph::key {'client.bootstrap-osd':
         keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
         secret       => $bootstrap_osd_key,
      }
    }

    node /client/ {
   
      class { 'ceph': }
      
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_initial_members => 'mon1,mon2,mon3',
        mon_host            => '<ip of mon1>,<ip of mon2>,<ip of mon3>',
      }
      
      ceph::key { 'client.admin':
        secret => $admin_key
      }
    }
    
    node /rgw*/ {
    	class { 'ceph': 
	
	# there is a separate radosgw class to define some basic requires needed before defining systemd units in the resource
        class { 'ceph::radosgw' }
	
	ceph::cluster { 'ceph':
        	fsid                => $fsid,
        	mon_initial_members => 'mon1,mon2,mon3',
        	mon_host            => '<ip of mon1>,<ip of mon2>,<ip of mon3>',
        }
        
        ceph::rgw { "radosgw-${::hostname}": 
		ssl_cert => '/path/to/combined-key-cert.pem',
		ssl_ca_file => '/etc/pki/tls/certs/ca-bundle.crt',
		port => '443s',
		
	}

    
    }
```

I want to run benchmarks on three new machines
----------------------------------------------

_Notice : Please note that the code below is a sample which is not expected to work without further configuration. You will need to at least adapt the hostnames, the IP address of the monitor host and the OSD disks to your setup._

There are four machines, 3 OSDs, one of which also doubles as the single monitor and one machine that is the client from which the user runs the benchmark.

On all four machines:
* install puppet and this module and its dependences (see metadata.json)
* paste the snippet below into /tmp/ceph.puppet
* `puppet apply /tmp/ceph.puppet`

On the client:
* `rados bench`
* interpret the results

```
    $fsid = '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'

    node /node1/ {
      class { 'ceph': }
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_host            => '<ip of node1>',
        mon_initial_members => 'node1',
        authentication_type => 'none',
      }
      ceph::mon { $::hostname:
        authentication_type => 'none',
      }

      Ceph::osd {
        db_size = "50%"
      }

      ceph::osd {
      '<disk1>':
        db => '<db for disk1>';
      '<disk2>':
        db => '<db for disk2>';
      }
    }

    node /node[23]/ {
      class { 'ceph': }
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_host            => '<ip of node1>',
        mon_initial_members => 'node1',
        authentication_type => 'none',
      }

      Ceph::osd {
        db_size = "50%"
      }

      ceph::osd {
      '<disk1>':
        db => '<db for disk1>';
      '<disk2>':
        db => '<db for disk2>';
      }
    }

    node /client/ {
      class { 'ceph': }
      ceph::cluster { 'ceph':
        fsid                => $fsid,
        mon_host            => '<ip of node1>',
        mon_initial_members => 'node1',
        authentication_type => 'none',
      }
    }
```

