#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2014 Nine Internet Solutions AG
#   Copyright (C) 2014 Catalyst IT Limited
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
# Author: Francois Charlier <francois.charlier@enovance.com>
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: Andrew Woodward <awoodward@mirantis.com>
# Author: David Gurtner <aldavud@crimson.ch>
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#
# == Class: ceph::repo
#
# Configure ceph APT repo for Ceph
#
# === Parameters:
#
# [*ensure*] The ensure state for package ressources.
#  Optional. Defaults to 'present'.
#
# [*release*] The name of the Ceph release to install
#   Optional. Default to 'giant'.
#
# [*extras*] Install Ceph Extra APT repo.
#   Optional. Defaults to 'false'.
#
# [*fastcgi*] Install Ceph fastcgi apache module for Ceph
#   Optional. Defaults to 'false'
#
class ceph::repo (
  $ensure  = present,
  $release = 'giant',
  $extras  = false,
  $fastcgi = false,
) {
  case $::osfamily {
    'Debian': {
      include ::apt

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

      if $extras {

        apt::source { 'ceph-extras':
          ensure   => $ensure,
          location => 'http://ceph.com/packages/ceph-extras/debian/',
          release  => $::lsbdistcodename,
          require  => Apt::Key['ceph'],
        }

      }

      if $fastcgi {

        apt::key { 'ceph-gitbuilder':
          ensure     => $ensure,
          key        => '6EAEAE2203C3951A',
          key_server => 'keyserver.ubuntu.com',
        }

        apt::source { 'ceph-fastcgi':
          ensure   => $ensure,
          location => "http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-${::lsbdistcodename}-${::hardwaremodel}-basic/ref/master",
          release  => $::lsbdistcodename,
          require  => Apt::Key['ceph-gitbuilder'],
        }

      }

      Apt::Source<| tag == 'ceph' |> -> Package<| tag == 'ceph' |>
      Exec['apt_update'] -> Package<| tag == 'ceph' |>
    }

    'RedHat': {
      $enabled = $ensure ? { 'present' => '1', 'absent' => '0', default => absent, }
      yumrepo { 'ext-epel-6.8':
        # puppet versions prior to 3.5 do not support ensure, use enabled instead
        enabled    => $enabled,
        descr      => 'External EPEL 6.8',
        name       => 'ext-epel-6.8',
        baseurl    => absent,
        gpgcheck   => '0',
        gpgkey     => absent,
        mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
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

      if $extras {

        yumrepo { 'ext-ceph-extras':
          enabled    => $enabled,
          descr      => 'External Ceph Extras',
          name       => 'ext-ceph-extras',
          baseurl    => 'http://ceph.com/packages/ceph-extras/rpm/rhel6/$basearch',
          gpgcheck   => '1',
          gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
          mirrorlist => absent,
          priority   => '10', # prefer ceph repos over EPEL
          tag        => 'ceph',
        }

      }

      if $fastcgi {

        yumrepo { 'ext-ceph-fastcgi':
          enabled    => $enabled,
          descr      => 'FastCGI basearch packages for Ceph',
          name       => 'ext-ceph-fastcgi',
          baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel6-x86_64-basic/ref/master',
          gpgcheck   => '1',
          gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
          mirrorlist => absent,
          priority   => '20', # prefer ceph repos over EPEL
          tag        => 'ceph',
        }

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
