#   Copyright (C) iWeb Technologies Inc.
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
# Author: François Charlier <francois.charlier@enovance.com>
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: Andrew Woodward <xarses>
#
# Configures Ceph's official repository for Ubuntu LTS
#
class ceph::repo (
  $release = 'cuttlefish'
) {
  case $::osfamily {
    'Debian': {
      include apt::update

      apt::key { 'ceph':
        key        => '17ED316D',
        key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
      }

      apt::source { 'ceph':
        location => "http://ceph.com/debian-${release}/",
        release  => $::lsbdistcodename,
        require  => Apt::Key['ceph'],
      }

      Exec['apt_update'] -> Package<||>
    }

    'RedHat': {
      yumrepo { 'ext-epel-6.8':
        descr      => 'External EPEL 6.8',
        name       => 'ext-epel-6.8',
        baseurl    => absent,
        gpgcheck   => '0',
        gpgkey     => absent,
        #mirrorlist => "https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=\${basearch}",
        # This is needed to avoid warning (using double-quotes) in puppet-lint
        # Can be removed when https://github.com/rodjek/puppet-lint/pull/234 is merged
        mirrorlist => join(['https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$', '{basearch}'], '')
      }

      yumrepo { 'ext-ceph':
        descr      => "External Ceph ${release}",
        name       => "ext-ceph-${release}",
        baseurl    => "http://ceph.com/rpm-${release}/el6/\${basearch}",
        gpgcheck   => '1',
        gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        mirrorlist => absent,
      }

      yumrepo { 'ext-ceph-noarch':
        descr      => 'External Ceph noarch',
        name       => "ext-ceph-${release}-noarch",
        baseurl    => "http://ceph.com/rpm-${release}/el6/noarch",
        gpgcheck   => '1',
        gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        mirrorlist => absent,
      }
    }

    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only supports osfamily Debian and RedHat")
    }
  }
}