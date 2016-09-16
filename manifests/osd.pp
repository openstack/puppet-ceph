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
#   Mandatory. A path in which the OSD data is to be stored.
#
# [*ensure*] Installs ( present ) or remove ( absent ) an OSD
#   Optional. Defaults to present.
#   If set to absent, it will stop the OSD service and remove
#   the associated data directory.
#
# [*journal*] The OSD journal path.
#   Optional. Defaults to co-locating the journal with the data
#   defined by *title*.
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
define ceph::osd (
  $ensure = present,
  $journal = undef,
  $cluster = undef,
  $exec_timeout = $::ceph::params::exec_timeout,
  $selinux_file_context = 'ceph_var_lib_t',
  $fsid = $::ceph::profile::params::fsid,
  ) {

    $data = $name

    if $cluster {
      $cluster_option = "--cluster ${cluster}"
      $cluster_name = $cluster
    } else {
      $cluster_name = 'ceph'
    }

    if $ensure == present {

      $ceph_check_udev = "ceph-osd-check-udev-${name}"
      $ceph_prepare = "ceph-osd-prepare-${name}"
      $ceph_activate = "ceph-osd-activate-${name}"

      Package<| tag == 'ceph' |> -> Exec[$ceph_check_udev]
      Ceph_config<||> -> Exec[$ceph_prepare]
      Ceph::Mon<||> -> Exec[$ceph_prepare]
      Ceph::Key<||> -> Exec[$ceph_prepare]

      $udev_rules_file = '/usr/lib/udev/rules.d/95-ceph-osd.rules'
      exec { $ceph_check_udev:
        command   => "/bin/true # comment to satisfy puppet syntax requirements
# Before Infernalis the udev rules race causing the activation to fail so we
# disable them. More at: http://www.spinics.net/lists/ceph-devel/msg28436.html
mv -f ${udev_rules_file} ${udev_rules_file}.disabled && udevadm control --reload || true
",
        onlyif    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
DISABLE_UDEV=\$(ceph --version | awk 'match(\$3, /[0-9]+\\.[0-9]+/) {if (substr(\$3, RSTART, RLENGTH) <= 0.94) {print 1}}')
test -f ${udev_rules_file} && test \$DISABLE_UDEV -eq 1
",
        logoutput => true,
      }

      if $fsid {
        $fsid_option = "--cluster-uuid ${fsid}"
        $ceph_check_fsid_mismatch = "ceph-osd-check-fsid-mismatch-${name}"
        Exec[$ceph_check_udev] -> Exec[$ceph_check_fsid_mismatch]
        Exec[$ceph_check_fsid_mismatch] -> Exec[$ceph_prepare]
        # return error if ${data} has fsid differing from ${fsid}, unless there is no fsid
        exec { $ceph_check_fsid_mismatch:
          command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test ${fsid} = \$(ceph-disk list ${data} | egrep -o '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}')
",
          unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test -z \$(ceph-disk list ${data} | egrep -o '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}')
",
          logoutput => true,
          timeout   => $exec_timeout,
        }
      }

      Exec[$ceph_check_udev] -> Exec[$ceph_prepare]
      # ceph-disk: prepare should be idempotent http://tracker.ceph.com/issues/7475
      exec { $ceph_prepare:
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if ! test -b ${data} ; then
    mkdir -p ${data}
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph ${data}
    fi
fi
ceph-disk prepare ${cluster_option} ${fsid_option} ${data} ${journal}
udevadm settle
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | grep -E ' *${data}1? .*ceph data, (prepared|active)' ||
{ test -f ${data}/fsid && test -f ${data}/ceph_fsid && test -f ${data}/magic ;}
",
        logoutput => true,
        timeout   => $exec_timeout,
      }
      if (str2bool($::selinux) == true) {
        ensure_packages($::ceph::params::pkg_policycoreutils, {'ensure' => 'present'})
        exec { "fcontext_${name}":
          command => "semanage fcontext -a -t ${selinux_file_context} '${data}(/.*)?' && restorecon -R ${data}",
          path    => ['/usr/sbin', '/sbin', '/usr/bin', '/bin'],
          require => [Package[$::ceph::params::pkg_policycoreutils],Exec[$ceph_prepare]],
          before  => Exec[$ceph_activate],
          unless  => "test -b ${data} || (semanage fcontext -l | grep ${data})",
        }
      }

      Exec[$ceph_prepare] -> Exec[$ceph_activate]
      exec { $ceph_activate:
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if ! test -b ${data} ; then
    mkdir -p ${data}
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph ${data}
    fi
fi
# activate happens via udev when using the entire device
if ! test -b ${data} || ! test -b ${data}1 ; then
  ceph-disk activate ${data} || true
fi
if test -f ${udev_rules_file}.disabled && test -b ${data}1 ; then
  ceph-disk activate ${data}1 || true
fi
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ls -ld /var/lib/ceph/osd/${cluster_name}-* | grep ' ${data}\$'
",
        logoutput => true,
      }

    } elsif $ensure == absent {

      # ceph-disk: support osd removal http://tracker.ceph.com/issues/7454
      exec { "remove-osd-${name}":
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | sed -nEe 's:^ *${data}1? .*(ceph data|mounted on).*osd\\.([0-9]+).*:\\2:p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ls -ld /var/lib/ceph/osd/${cluster_name}-* | sed -nEe 's:.*/${cluster_name}-([0-9]+) *-> *${data}\$:\\1:p' || true)
fi
if [ \"\$id\" ] ; then
  stop ceph-osd cluster=${cluster_name} id=\$id || true
  service ceph stop osd.\$id || true
  systemctl stop ceph-osd@\$id || true
  ceph ${cluster_option} osd crush remove osd.\$id
  ceph ${cluster_option} auth del osd.\$id
  ceph ${cluster_option} osd rm \$id
  rm -fr /var/lib/ceph/osd/${cluster_name}-\$id/*
  umount /var/lib/ceph/osd/${cluster_name}-\$id || true
  rm -fr /var/lib/ceph/osd/${cluster_name}-\$id
fi
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | sed -nEe 's:^ *${data}1? .*(ceph data|mounted on).*osd\\.([0-9]+).*:\\2:p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ls -ld /var/lib/ceph/osd/${cluster_name}-* | sed -nEe 's:.*/${cluster_name}-([0-9]+) *-> *${data}\$:\\1:p' || true)
fi
if [ \"\$id\" ] ; then
  test ! -d /var/lib/ceph/osd/${cluster_name}-\$id
else
  true # if there is no id  we do nothing
fi
",
        logoutput => true,
        timeout   => $exec_timeout,
      } -> Ceph::Mon<| ensure == absent |>
    } else {
      fail('Ensure on OSD must be either present or absent')
    }
}
