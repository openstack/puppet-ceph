#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
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
# Author: François Charlier <francois.charlier@enovance.com>
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: Andrew Woodward <awoodward@mirantis.com>
# Author: David Gurtner <david@nine.ch>
#
class ceph::repo (
  $ensure  = present,
  $release = 'firefly'
) {
  case $::osfamily {
    'Debian': {
      include apt

      apt::key { 'ceph':
        ensure     => $ensure,
        key        => '17ED316D',
        key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
      }

      apt::source { 'ceph':
        ensure   => $ensure,
        location => "http://ceph.com/debian-${release}/",
        release  => $::lsbdistcodename,
        require  => Apt::Key['ceph'],
        tag      => 'ceph',
      }

      Apt::Source<| tag == 'ceph' |> -> Package<| tag == 'ceph' |>
      Exec['apt_update'] -> Package<| tag == 'ceph' |>
    }

    'RedHat': {
      $enabled = $ensure ? { present => '1', absent => '0', default => absent, }
      yumrepo { 'ext-epel-6.8':
        # puppet versions prior to 3.5 do not support ensure, use enabled instead
        enabled    => $enabled,
        descr      => 'External EPEL 6.8',
        name       => 'ext-epel-6.8',
        baseurl    => absent,
        gpgcheck   => '0',
        gpgkey     => absent,
        mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        priority   => '20', # prefer ceph repos over EPEL
        tag        => 'ceph',
      }

      yumrepo { 'ext-ceph':
        # puppet versions prior to 3.5 do not support ensure, use enabled instead
        enabled    => $enabled,
        descr      => "External Ceph ${release}",
        name       => "ext-ceph-${release}",
        baseurl    => "http://ceph.com/rpm-${release}/el6/\$basearch",
        gpgcheck   => '1',
        gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        mirrorlist => absent,
        priority   => '10', # prefer ceph repos over EPEL
        tag        => 'ceph',
      }

      yumrepo { 'ext-ceph-noarch':
        # puppet versions prior to 3.5 do not support ensure, use enabled instead
        enabled    => $enabled,
        descr      => 'External Ceph noarch',
        name       => "ext-ceph-${release}-noarch",
        baseurl    => "http://ceph.com/rpm-${release}/el6/noarch",
        gpgcheck   => '1',
        gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        mirrorlist => absent,
        priority   => '10', # prefer ceph repos over EPEL
        tag        => 'ceph',
      }

      Yumrepo<| tag == 'ceph' |> -> Package<| tag == 'ceph' |>

      # prefer ceph repos over EPEL
      package { 'yum-plugin-priorities':
        ensure => present,
      }

    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only supports osfamily Debian and RedHat")
    }
  }
}
