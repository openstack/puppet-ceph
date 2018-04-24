#
#   Copyright (C) 2014 Cloudwatt <libre.licensing@cloudwatt.com>
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
# Author: Loic Dachary <loic@dachary.org>
# Author: David Gurtner <aldavud@crimson.ch>
#
# == Define: ceph::osd
#
# Install and configure a ceph OSD
#
# === Parameters:
#
# [*title*] The OSD data path.
#   Mandatory. The path for a disk or vg/lv used for the OSD
#
# [*ensure*] Installs ( present ) or remove ( absent ) an OSD
#   Optional. Defaults to present.
#   If set to absent, it will stop the OSD service and remove
#   the associated data directory.
#
# [*journal*] The OSD filestore journal path.
#   Optional. Defaults to co-locating the journal with the data
#   defined by *title*.
#
# [*bluestore_wal*] The OSD bluestore WAL path.
#   Optional. Defaults to co-locating the WAL with the data
#   defined by *title*.
#
# [*bluestore_db*] The OSD bluestore WAL path.
#   Optional. Defaults to co-locating the DB with the data
#   defined by *title*.
#
# [*store_type*] The OSD backing store type.
#   Optional. Defaults undef and will follow the ceph version default.
#   should be either filestore or bluestore.
#
# [*cluster*] The ceph cluster
#   Optional. Same default as ceph.
#
# [*exec_timeout*] The default exec resource timeout, in seconds
#   Optional. Defaults to $::ceph::params::exec_timeout
#
# [*selinux_file_context*] The SELinux file context to apply
#   on the directory backing the OSD service.
#   Optional. Defaults to 'ceph_var_lib_t'
#
# [*fsid*] The ceph cluster FSID
#   Optional. Defaults to $::ceph::profile::params::fsid
#
# [*dmcrypt*] Encrypt [data-path] and/or journal devices with dm-crypt.
#   Optional. Defaults to false.
#
# [*dmcrypt_key_dir*] Directory where dm-crypt keys are stored.
#   Optional. Defaults to '/etc/ceph/dmcrypt-keys'.
#
define ceph::osd (
  $ensure = present,
  $journal = undef,
  $cluster = undef,
  $bluestore_wal = undef,
  $bluestore_db = undef,
  $store_type = undef,
  $exec_timeout = $::ceph::params::exec_timeout,
  $selinux_file_context = 'ceph_var_lib_t',
  $fsid = $::ceph::profile::params::fsid,
  $dmcrypt = false,
  $dmcrypt_key_dir = '/etc/ceph/dmcrypt-keys',
  ) {

    include ::ceph::params

    $data = $name

    if $cluster {
      $cluster_name = $cluster
    } else {
      $cluster_name = 'ceph'
    }
    $cluster_option = "--cluster ${cluster_name}"

    if $store_type {
      $osd_type = "--${store_type}"
    }

    if ($bluestore_wal) or ($bluestore_db) {
      if $bluestore_wal {
        $wal_opts = "--block.wal ${bluestore_wal}"
      }
      if $bluestore_db {
        $block_opts = "--block.db ${bluestore_db}"
      }
      $journal_opts = "${wal_opts} ${block_opts}"

    } elsif $journal {
      $journal_opts = "--journal ${journal}"
    } else {
      $journal_opts = ''
    }

    if $dmcrypt {
      $dmcrypt_options = " --dmcrypt --dmcrypt-key-dir '${dmcrypt_key_dir}'"
    } else {
      $dmcrypt_options = ''
    }

    if $ensure == present {

      $ceph_prepare = "ceph-osd-prepare-${name}"
      $ceph_activate = "ceph-osd-activate-${name}"

      Ceph_config<||> -> Exec[$ceph_prepare]
      Ceph::Mon<||> -> Exec[$ceph_prepare]
      Ceph::Key<||> -> Exec[$ceph_prepare]

      # Ensure none is activated before prepare is finished for all
      Exec<| tag == 'prepare' |> -> Exec<| tag == 'activate' |>

      if $fsid {
        $fsid_option = "--cluster-fsid ${fsid}"
        $ceph_check_fsid_mismatch = "ceph-osd-check-fsid-mismatch-${name}"
        Exec[$ceph_check_fsid_mismatch] -> Exec[$ceph_prepare]
        # return error if $(readlink -f ${data}) has fsid differing from ${fsid}, unless there is no fsid
        exec { $ceph_check_fsid_mismatch:
          command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
exit 1
",
          unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z $(ceph-volume lvm list ${data} |grep 'cluster fsid' | awk -F'fsid' '{print \$2}'|tr -d  ' ') ]; then
    exit 0
fi
test ${fsid} = $(ceph-volume lvm list ${data} |grep 'cluster fsid' | awk -F'fsid' '{print \$2}'|tr -d  ' ')
",
          logoutput => true,
          timeout   => $exec_timeout,
        }
      }

      #name of the bootstrap osd keyring
      $bootstrap_osd_keyring = "/var/lib/ceph/bootstrap-osd/${cluster_name}.keyring"
      exec { "extract-bootstrap-osd-keyring-${name}":
        command => "/bin/true # comment to satisfy puppet syntax requirements
ceph auth get client.bootstrap-osd > ${bootstrap_osd_keyring}
",
        creates => "${bootstrap_osd_keyring}",
      }
      Exec["extract-bootstrap-osd-keyring-${name}"] -> Exec[$ceph_prepare]

      exec { $ceph_prepare:
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo ${data}|cut -c 1) = '/' ]; then
    disk=${data}
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/${data}
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare ${osd_type} ${cluster_option}${dmcrypt_options} ${fsid_option} --data ${data} ${journal_opts}
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list ${data}
",
        logoutput => true,
        timeout   => $exec_timeout,
        tag       => 'prepare',
      }
      if (str2bool($::selinux) == true) {
        ensure_packages($::ceph::params::pkg_policycoreutils, {'ensure' => 'present'})
        exec { "fcontext_${name}":
          command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
semanage fcontext -a -t ${selinux_file_context} \"$(readlink -f ${data})(/.*)?\"
restorecon -R $(readlink -f ${data})
",
          require => [Package[$::ceph::params::pkg_policycoreutils],Exec[$ceph_prepare]],
          before  => Exec[$ceph_activate],
          unless  => "/usr/bin/test -b $(readlink -f ${data}) || (semanage fcontext -l | grep $(readlink -f ${data}))",
        }
      }

      Exec[$ceph_prepare] -> Exec[$ceph_activate]
      exec { $ceph_activate:
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo ${data}|cut -c 1) = '/' ]; then
    disk=${data}
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/${data}
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list ${data} | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list ${data} | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list ${data} | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        logoutput => true,
        tag       => 'activate',
      }

    } elsif $ensure == absent {

      # ceph-disk: support osd removal http://tracker.ceph.com/issues/7454
      exec { "remove-osd-${name}":
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list ${data} | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
if [ \"\$id\" ] ; then
  ceph ${cluster_option} osd out osd.\$id
  stop ceph-osd cluster=${cluster_name} id=\$id || true
  service ceph stop osd.\$id || true
  systemctl stop ceph-osd@\$id || true
  ceph ${cluster_option} osd crush remove osd.\$id
  ceph ${cluster_option} auth del osd.\$id
  ceph ${cluster_option} osd rm \$id
  rm -fr /var/lib/ceph/osd/${cluster_name}-\$id/*
  umount /var/lib/ceph/osd/${cluster_name}-\$id || true
  rm -fr /var/lib/ceph/osd/${cluster_name}-\$id
  ceph-volume lvm zap ${data}
fi
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -x
ceph-volume lvm list ${data}
if [ \$? -eq 0 ]; then
    exit 1
else
    exit 0
fi
",
        logoutput => true,
        timeout   => $exec_timeout,
      } -> Ceph::Mon<| ensure == absent |>
    } else {
      fail('Ensure on OSD must be either present or absent')
    }
}
