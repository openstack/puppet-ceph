#
#   Copyright (C) 2014 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2014 Nine Internet Solutions AG
#   Copyright (C) 2018 University of Michigan, funded by the NSF OSiRIS Project
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
# Author: Loic Dachary <loic@dachary.org>
# Author: David Gurtner <aldavud@crimson.ch>
# Author: Ben Meekhof <bmeekhof@umich.edu>
#
# == Define: ceph::osd
#
# Install and configure a ceph OSD.  This module does not support multiple clusters on the same host.
# As part of configuration it sets the system-wide cluster in /etc/sysconfig/ceph
# This resource does not support creating filestore OSD and uses ceph-volume to create OSD
#
# === Parameters:
#
# [*title*] The OSD data path.
#   Mandatory. A path in which the OSD data is to be stored.
#
# [*ensure*] Installs ( present ) or remove ( absent ) an OSD
#   Optional. Defaults to present.  ** Setting 'absent' not currently supported. **
#   If set to absent, it will stop the OSD service and remove
#   the associated data directory.
#
# [*db*] The OSD block db path.  
#   if create_lv is true will create VG/LV on device and pass them to ceph-volume
#   If create_lv is false the db param will be passed directly to ceph-volume 
#   Optional. Defaults to co-locating the db with the data
#   defined by *name*.  If VG and LV exist matching names by this module they will be re-used.
#
# [*db_size*] How large to make the block db LV.  If not specified defaults to 100% of device. 
# Can be specified as a percentage or with LV units like 10G, etc.  If a percentage then a bash
# calculation is used to multiply specified (percentage * volume group extents) so you may use decimals
# in the percentage (lvcreate itself only accepts integer %)
# 
# [*db_per_device*] Divide the given block device up into this many LV.  Does a bash calculation 
# taking integer part of (total volume group extents / db_per_device).  
# Specifying both db_size and db_per_device will cause compilation failure. 
#
# [*create_lv*]  If true this module will create logical volumes for data, db, and wal devs 
#    If false then the module title and db param are assumed to be existing LV (or partition for block/wal is acceptable)
#    LV are named as follows, example of name = /dev/mapper/mpatha, db = /dev/nvme0n1
#    vgdb_nvme0n1/db_mpatha
#    vgdata_mpatha/data_mpatha
# 
# [*cluster*] The ceph cluster
#   Optional. Same default as ceph.
#
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to $::ceph::params::exec_timeout
#

define ceph::osd (
  Enum['present', 'absent'] $ensure = present,
  Optional[String] $db = undef,
  Optional[String] $db_size = undef,
  Optional[Integer] $db_per_device = undef,
  Optional[String] $wal = undef,
  Optional[String] $wal_size = '100%',
  Boolean $create_lv = true,
  String $cluster = 'ceph',
  Integer $exec_timeout = $::ceph::params::exec_timeout,
  ) {

    $data = $name
    $data_basename = basename($data)

    if ($db_size and $db_per_device) {
      fail("Cannot specify both db_size and db_per_device together")
    }

    if $wal {
      fail('WAL specification is not yet implemented')
    }

    unless $cluster == 'ceph' {
      $cluster_option = "--cluster ${cluster}"
      $cluster_name = $cluster

      # some adjustments may be needed for non-RHEL setup
      file_line { "sysconfig-${cluster}-${name}":
        path => "/etc/sysconfig/ceph",
        line => "CLUSTER=${cluster}",
        match => 'CLUSTER=.*',
        ensure => $ensure
      }

      File_line["sysconfig-${cluster}-${name}"] -> Exec["create-osd-${data_basename}"]

    } else {
      $cluster_name = $cluster
    }

    # FIXME (maybe): There's no provision to pass in a size specified in extents
    # if db_per_device then take integer part of (total extents / device count)
    # bash doesn't do floating point so we're assured of an integer result 
    # if db_size is % then take (percentage * total extents)
    # using 'bc' to do a fp multiplication in above case
    
    # VGE and LVE are calculated in shell
    # the strings set here are passed into /bin/sh to set vars in the shell 
    if $db_size {
      if '%' in $db_size {
        $db_size_decimal = chop($db_size) / 100
        $lv_extents = "\$(bc <<< \"\$VGE * $db_size_decimal / 1\")"
        $lv_size_flag = "-l\${LVE}"
      } else {
        $lv_size_flag = "-L${db_size}"
      }
    } elsif $db_per_device {
      $lv_extents =  "\$((\$VGE / $db_per_device))"
      $lv_size_flag = "-l\${LVE}"
    } else {
      $lv_size_flag = "-l100%VG"
      $lv_extents = 'undef'
    }

    Exec { 
      path => [ '/sbin', '/usr/sbin', '/bin', '/usr/bin' ],
    }

    if $ensure == present {

      Ceph_config<||> -> Exec["create-osd-${data_basename}"]
      Ceph::Mon<||> -> Exec["create-osd-${data_basename}"]
      Ceph::Key<||> -> Exec["create-osd-${data_basename}"]

      if $db {
        $db_basename = basename($db)

        if $create_lv {

          $vg_extents = "\$(vgs vgdb_${db_basename} -o +vg_free_count,vg_extent_count -o-pv_count,lv_count,vg_name,vg_attr,snap_count,vg_size,vg_free,vg_free_count --noheadings --quiet)"

          exec { "create-db-vg-${data_basename}":
            command => "vgcreate vgdb_${db_basename} ${db}",
            unless => "vgs | grep -q vgdb_${db_basename}[[:space:]]",
            onlyif => 'test -b ${db}'
          } ->

          exec { "create-db-lv-${data_basename}":
            # have to use shell provider to use features 
            provider => shell,
            command => "VGE=$vg_extents; LVE=$lv_extents; lvcreate ${lv_size_flag} -n db_${data_basename} vgdb_${db_basename}",
            unless => "lvs | grep -q db_${data_basename}[[:space:]]"
          }

          Exec["create-db-lv-${data_basename}"] -> 
          Exec["create-data-vg-${data_basename}"]
          
          $block_lv = "vgdb_${db_basename}/db_${data_basename}"

        } else {
          $block_lv = $db
        }
        $block_db_cl = "--block.db $block_lv"
      } else {
        $block_db_cl = ''
      }

      if $create_lv {
        exec { "create-data-vg-${data_basename}":
          command => "vgcreate vgdata_${data_basename} ${data}",
          unless => "vgs | grep -q vgdata_${data_basename}[[:space:]]",
          onlyif => 'test -b ${data}'
        } ->

        exec { "create-data-lv-${data_basename}":
          command => "lvcreate -l100%VG -n data_${data_basename} vgdata_${data_basename}",
          unless => "lvs | grep -q data_${data_basename}[[:space:]]"
        } 

        Exec["create-data-lv-${data_basename}"] -> Exec["create-osd-${data_basename}"]

        $data_lv = "vgdata_${data_basename}/data_${data_basename}"

      } else {
        $data_lv = $data
      }
      
      exec { "create-osd-${data_basename}":
        command => "ceph-volume lvm create --bluestore --data ${data_lv} ${block_db_cl}",
        unless => "ls -l /var/lib/ceph/osd/${cluster_name}-* | grep -q ${data_lv}"
      }

    } else {
      fail('Only ensure => present is supported, must remove OSD manually.  See comments in manifest for code that could be implemented again.')
    }
}







#    We may choose to re-implement this someday but at this point I have never used it to remove OSD
#    For this to work it has to be defined somewhere with an admin key available to delete the OSD
# 
#       # ceph-disk: support osd removal http://tracker.ceph.com/issues/7454
#       exec { "remove-osd-${name}":
#         command   => "/bin/true # comment to satisfy puppet syntax requirements
# set -ex
# if [ -z \"\$id\" ] ; then
#   id=\$(ceph-disk list | sed -nEe 's:^ *${data}1? .*(ceph data|mounted on).*osd\\.([0-9]+).*:\\2:p')
# fi
# if [ -z \"\$id\" ] ; then
#   id=\$(ls -ld /var/lib/ceph/osd/${cluster_name}-* | sed -nEe 's:.*/${cluster_name}-([0-9]+) *-> *${data}\$:\\1:p' || true)
# fi
# if [ \"\$id\" ] ; then
#   stop ceph-osd cluster=${cluster_name} id=\$id || true
#   service ceph stop osd.\$id || true
#   ceph ${cluster_option} osd crush remove osd.\$id
#   ceph ${cluster_option} auth del osd.\$id
#   ceph ${cluster_option} osd rm \$id
#   rm -fr /var/lib/ceph/osd/${cluster_name}-\$id/*
#   umount /var/lib/ceph/osd/${cluster_name}-\$id || true
#   rm -fr /var/lib/ceph/osd/${cluster_name}-\$id
# fi
# ",
#         unless    => "/bin/true # comment to satisfy puppet syntax requirements
# set -ex
# if [ -z \"\$id\" ] ; then
#   id=\$(ceph-disk list | sed -nEe 's:^ *${data}1? .*(ceph data|mounted on).*osd\\.([0-9]+).*:\\2:p')
# fi
# if [ -z \"\$id\" ] ; then
#   id=\$(ls -ld /var/lib/ceph/osd/${cluster_name}-* | sed -nEe 's:.*/${cluster_name}-([0-9]+) *-> *${data}\$:\\1:p' || true)
# fi
# if [ \"\$id\" ] ; then
#   test ! -d /var/lib/ceph/osd/${cluster_name}-\$id
# else
#   true # if there is no id  we do nothing
# fi
# ",
#         logoutput => true,
#         timeout   => $exec_timeout,
#       } -> Ceph::Mon<| ensure == absent |>
#     }
# 
# }
