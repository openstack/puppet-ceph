#
#   Copyright (C) 2014 Cloudwatt <libre.licensing@cloudwatt.com>
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
# Author: David Gurtner <david@nine.ch>
#
### == Parameters
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
define ceph::osd (
  $ensure = present,
  $journal = undef,
  $cluster = undef,
  ) {

    $data = $name

    if $cluster {
      $cluster_option = "--cluster ${cluster}"
    }

    if $ensure == present {
      $ceph_mkfs = "ceph-osd-mkfs-${name}"

      # ceph-disk: prepare should be idempotent http://tracker.ceph.com/issues/7475
      exec { $ceph_mkfs:
        command   => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
/usr/sbin/ceph-disk prepare ${cluster_option} ${data} ${journal}
/usr/sbin/ceph-disk activate ${cluster_option} ${data}
",
        unless    => "/usr/sbin/ceph-disk list | grep ' *${data}.*ceph data'",
        logoutput => true,
      }

    } else {

      # ceph-disk: support osd removal http://tracker.ceph.com/issues/7454
      exec { "remove-osd-${name}":
        command   => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | grep ' *${data}.*ceph data' | sed -ne 's/.*osd.\\([0-9][0-9]*\\).*/\\1/p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | grep ' *${data}.*mounted on' | sed -ne 's/.*osd.\\([0-9][0-9]*\\)\$/\\1/p')
fi
if [ \"\$id\" ] ; then
  stop ceph-osd cluster=${cluster} id=\$id || true
  ceph ${cluster_option} osd rm \$id
  ceph auth del osd.\$id
  umount /var/lib/ceph/osd/ceph-\$id || true
  rm -fr /var/lib/ceph/osd/ceph-\$id
fi
",
        logoutput => true,
      }
    }

}
