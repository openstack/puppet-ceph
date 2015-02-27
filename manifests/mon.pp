#
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
#
# == Define: ceph::mon
#
# Installs and configures MONs (ceph monitors)
#
# === Parameters:
#
# [*title*] The MON id.
#   Mandatory. An alphanumeric string uniquely identifying the MON.
#
# [*ensure*] Installs ( present ) or remove ( absent ) a MON
#   Optional. Defaults to present.
#   If set to absent, it will stop the MON service and remove
#   the associated data directory.
#
# [*public_addr*] The bind IP address.
#   Optional. The IPv(4|6) address on which MON binds itself.
#
# [*cluster*] The ceph cluster
#   Optional. Same default as ceph.
#
# [*authentication_type*] Activate or deactivate authentication
#   Optional. Default to cephx.
#   Authentication is activated if the value is 'cephx' and deactivated
#   if the value is 'none'. If the value is 'cephx', at least one of
#   key or keyring must be provided.
#
# [*key*] Authentication key for [mon.]
#   Optional. $key and $keyring are mutually exclusive.
#
# [*keyring*] Path of the [mon.] keyring file
#   Optional. $key and $keyring are mutually exclusive.
#
define ceph::mon (
  $ensure = present,
  $public_addr = undef,
  $cluster = undef,
  $authentication_type = 'cephx',
  $key = undef,
  $keyring  = undef,
  ) {

    # a puppet name translates into a ceph id, the meaning is different
    $id = $name

    if $cluster {
      $cluster_name = $cluster
      $cluster_option = "--cluster ${cluster_name}"
    } else {
      $cluster_name = 'ceph'
    }

    if $::operatingsystem == 'Ubuntu' {
      $init = 'upstart'
      Service {
        name     => "ceph-mon-${id}",
        # workaround for bug https://projects.puppetlabs.com/issues/23187
        provider => 'init',
        start    => "start ceph-mon id=${id}",
        stop     => "stop ceph-mon id=${id}",
        status   => "status ceph-mon id=${id}",
      }
    } elsif ($::operatingsystem == 'Debian') or ($::osfamily == 'RedHat') {
      $init = 'sysvinit'
      Service {
        name     => "ceph-mon-${id}",
        start    => "service ceph start mon.${id}",
        stop     => "service ceph stop mon.${id}",
        status   => "service ceph status mon.${id}",
      }
    } else {
      fail("operatingsystem = ${::operatingsystem} is not supported")
    }

    $mon_service = "ceph-mon-${id}"

    if $ensure == present {

      $ceph_mkfs = "ceph-mon-mkfs-${id}"

      if $authentication_type == 'cephx' {
        if ! $key and ! $keyring {
          fail("authentication_type ${authentication_type} requires either key or keyring to be set but both are undef")
        }
        if $key and $keyring {
          fail("key (set to ${key}) and keyring (set to ${keyring}) are mutually exclusive")
        }
        if $key {
          $keyring_path = "/tmp/ceph-mon-keyring-${id}"

          file { $keyring_path:
            mode    => '0444',
            content => "[mon.]\n\tkey = ${key}\n\tcaps mon = \"allow *\"\n",
          }

          File[$keyring_path] -> Exec[$ceph_mkfs]

        } else {
          $keyring_path = $keyring
        }

      } else {
        $keyring_path = '/dev/null'
      }

      if $public_addr {
        $public_addr_option = "--public_addr ${public_addr}"
      }

      Ceph_Config<||> ->
      exec { $ceph_mkfs:
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon ${cluster_option} --id ${id} --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon ${cluster_option} \
        ${public_addr_option} \
        --mkfs \
        --id ${id} \
        --keyring ${keyring_path} ; then
    touch \$mon_data/done \$mon_data/${init} \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        logoutput => true,
      }
      ->
      # prevent automatic creation of the client.admin key by ceph-create-keys
      exec { "ceph-mon-${cluster_name}.client.admin.keyring-${id}":
        command => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/${cluster_name}.client.admin.keyring",
      }
      ->
      service { $mon_service:
        ensure => running,
      }


      if $authentication_type == 'cephx' {
        if $key {
          Exec[$ceph_mkfs] -> Exec["rm-keyring-${id}"]

          exec { "rm-keyring-${id}":
            command => "/bin/rm ${keyring_path}",
          }
        }
      }

    } else {
      service { $mon_service:
        ensure => stopped
      }
      ->
      exec { "remove-mon-${id}":
        command   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon ${cluster_option} --id ${id} --show-config-value mon_data)
rm -fr \$mon_data
",
        unless    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
which ceph-mon || exit 0 # if ceph-mon is not available we already uninstalled ceph and there is nothing to do
mon_data=\$(ceph-mon ${cluster_option} --id ${id} --show-config-value mon_data)
test ! -d \$mon_data
",
        logoutput => true,
      } -> Package<| tag == 'ceph' |>
    }
  }
