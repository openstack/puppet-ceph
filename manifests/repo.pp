#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2014 Nine Internet Solutions AG
#   Copyright (C) 2014 Catalyst IT Limited
#   Copyright (C) 2015 Red Hat
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
# Author: Emilien Macchi <emilien@redhat.com>
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
#   Optional. Default to 'luminous' in ceph::params.
#
# [*fastcgi*] Install Ceph fastcgi apache module for Ceph
#   Optional. Defaults to 'false'
#
# [*proxy*] Proxy URL to be used for the yum repository, useful if you're behind a corporate firewall
#   Optional. Defaults to 'undef'
#
# [*proxy_username*] The username to be used for the proxy if one should be required
#   Optional. Defaults to 'undef'
#
# [*proxy_password*] The password to be used for the proxy if one should be required
#   Optional. Defaults to 'undef'
#
# [*enable_epel*] Whether or not enable EPEL repository.
#   Optional. Defaults to True
#
# [*enable_sig*] Whether or not enable SIG repository.
#   CentOS SIG repository contains Ceph packages built by CentOS community.
#   https://wiki.centos.org/SpecialInterestGroup/Storage/
#   Optional. Defaults to False in ceph::params.
#
# [*ceph_mirror*] Ceph mirror used to download packages.
#   Optional. Defaults to undef.
#
class ceph::repo (
  $ensure         = present,
  $release        = $::ceph::params::release,
  $fastcgi        = false,
  $proxy          = undef,
  $proxy_username = undef,
  $proxy_password = undef,
  $enable_epel    = true,
  $enable_sig     = $::ceph::params::enable_sig,
  $ceph_mirror    = undef,
) inherits ceph::params {
  case $::osfamily {
    'Debian': {
      include ::apt

      if $ceph_mirror {
        $ceph_mirror_real = $ceph_mirror
      } else {
        $ceph_mirror_real = "http://download.ceph.com/debian-${release}/"
        apt::key { 'ceph':
          ensure => $ensure,
          id     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
          source => 'https://download.ceph.com/keys/release.asc',
          before => Apt::Source['ceph'],
        }
      }

      apt::source { 'ceph':
        ensure   => $ensure,
        location => $ceph_mirror_real,
        release  => $::lsbdistcodename,
        tag      => 'ceph',
      }

      if $fastcgi {

        apt::key { 'ceph-gitbuilder':
          ensure => $ensure,
          id     => 'FCC5CB2ED8E6F6FB79D5B3316EAEAE2203C3951A',
          server => 'keyserver.ubuntu.com',
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

      # If you want to deploy Ceph using packages provided by CentOS SIG
      # https://wiki.centos.org/SpecialInterestGroup/Storage/
      if $enable_sig {
        if $::operatingsystem != 'CentOS' {
          warning("CentOS SIG repository is only supported on CentOS operating system, \
not on ${::operatingsystem}, which can lead to packaging issues.")
        }
        if $ceph_mirror {
          $ceph_mirror_real = $ceph_mirror
        } else {
          $ceph_mirror_real = "https://buildlogs.centos.org/centos/7/storage/x86_64/ceph-${release}/"
        }
        yumrepo { 'ceph-luminous-sig':
          enabled    => '1',
          baseurl    => $ceph_mirror_real,
          descr      => 'Ceph Luminous SIG',
          mirrorlist => 'absent',
          gpgcheck   => '0',
        }
        # Make sure we install the repo before any Package resource
        Yumrepo['ceph-luminous-sig'] -> Package<| tag == 'ceph' |>
      } else {
        # If you want to deploy Ceph using packages provided by ceph.com repositories.
        if ((($::operatingsystem == 'RedHat' or $::operatingsystem == 'CentOS') and (versioncmp($::operatingsystemmajrelease, '7') < 0))
              or ($::operatingsystem == 'Fedora' and (versioncmp($::operatingsystemmajrelease, '19') < 0))) {
          $el = '6'
        } else {
          $el = '7'
        }

        # Firefly is the last ceph.com supported release which conflicts with
        # the CentOS 7 base channel. Therefore make sure to only exclude the
        # conflicting packages in the exact combination of CentOS7 and Firefly.
        # TODO: Remove this once Firefly becomes EOL
        if ($::operatingsystem == 'CentOS' and $el == '7' and $release == 'firefly') {
          file_line { 'exclude base':
            ensure => $ensure,
            path   => '/etc/yum.repos.d/CentOS-Base.repo',
            after  => '^\[base\]$',
            line   => 'exclude=python-ceph-compat python-rbd python-rados python-cephfs',
          } -> Package<| tag == 'ceph' |>
        }

        Yumrepo {
          proxy          => $proxy,
          proxy_username => $proxy_username,
          proxy_password => $proxy_password,
        }


        yumrepo { 'ext-ceph':
          # puppet versions prior to 3.5 do not support ensure, use enabled instead
          enabled    => $enabled,
          descr      => "External Ceph ${release}",
          name       => "ext-ceph-${release}",
          baseurl    => "http://download.ceph.com/rpm-${release}/el${el}/\$basearch",
          gpgcheck   => '1',
          gpgkey     => 'https://download.ceph.com/keys/release.asc',
          mirrorlist => absent,
          priority   => '10', # prefer ceph repos over EPEL
          tag        => 'ceph',
        }

        yumrepo { 'ext-ceph-noarch':
          # puppet versions prior to 3.5 do not support ensure, use enabled instead
          enabled    => $enabled,
          descr      => 'External Ceph noarch',
          name       => "ext-ceph-${release}-noarch",
          baseurl    => "http://download.ceph.com/rpm-${release}/el${el}/noarch",
          gpgcheck   => '1',
          gpgkey     => 'https://download.ceph.com/keys/release.asc',
          mirrorlist => absent,
          priority   => '10', # prefer ceph repos over EPEL
          tag        => 'ceph',
        }

        if $fastcgi {
          yumrepo { 'ext-ceph-fastcgi':
            enabled    => $enabled,
            descr      => 'FastCGI basearch packages for Ceph',
            name       => 'ext-ceph-fastcgi',
            baseurl    => "http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel${el}-x86_64-basic/ref/master",
            gpgcheck   => '1',
            gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
            mirrorlist => absent,
            priority   => '20', # prefer ceph repos over EPEL
            tag        => 'ceph',
          }
        }

        # prefer ceph.com repos over EPEL
        package { 'yum-plugin-priorities':
          ensure => present,
        }
      }

      if $enable_epel {
        yumrepo { "ext-epel-${el}":
          # puppet versions prior to 3.5 do not support ensure, use enabled instead
          enabled    => $enabled,
          descr      => "External EPEL ${el}",
          name       => "ext-epel-${el}",
          baseurl    => absent,
          gpgcheck   => '1',
          gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-${el}",
          mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-${el}&arch=\$basearch",
          priority   => '20', # prefer ceph repos over EPEL
          tag        => 'ceph',
          exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
        }
      }

      Yumrepo<| tag == 'ceph' |> -> Package<| tag == 'ceph' |>
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, \
module ${module_name} only supports osfamily Debian and RedHat")
    }
  }
}
