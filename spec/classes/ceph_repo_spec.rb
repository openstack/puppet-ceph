# -*- coding: utf-8 -*-
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
# Author: Francois Charlier <francois.charlier@enovance.com>
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: Andrew Woodward <xarses>

require 'spec_helper'

describe 'ceph::repo' do
  shared_examples 'ceph::repo on Debian' do
    context 'with default params' do
      it { should contain_apt__key('ceph').with(
        :id     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :source => 'https://download.ceph.com/keys/release.asc',
        :before => 'Apt::Source[ceph]',
      )}

      it { should contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-nautilus/',
        :release  => facts[:os]['distro']['codename'],
      )}
    end

    context 'when overriding ceph mirror' do
      let :params do
        {
          :ceph_mirror => 'http://myserver.com/debian-nautilus/'
        }
      end

      it { should contain_apt__source('ceph').with(
        :location => 'http://myserver.com/debian-nautilus/',
        :release  => facts[:os]['distro']['codename'],
      )}
    end

    context 'with ensure => absent to disable' do
      let :params do
        {
          :ensure  => 'absent',
        }
      end

      it { should contain_apt__source('ceph').with(
        :ensure   => 'absent',
        :location => 'http://download.ceph.com/debian-nautilus/',
        :release  => facts[:os]['distro']['codename'],
      )}
    end
  end

  shared_examples 'ceph::repo on RedHat' do
    context 'with default params' do
      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure     => 'present',
        :descr      => "External EPEL #{facts[:os]['release']['major']}",
        :name       => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority   => '20',
        :exclude    => 'python3-rbd python3-rados python3-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure     => 'present',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure     => 'present',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end

    context 'when overriding ceph release' do
      let :params do
        {
          :release => 'firefly'
        }
      end

      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure     => 'present',
        :descr      => "External EPEL #{facts[:os]['release']['major']}",
        :name       => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority   => '20',
        :exclude    => 'python3-rbd python3-rados python3-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure     => 'present',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => "http://download.ceph.com/rpm-firefly/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure     => 'present',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => "http://download.ceph.com/rpm-firefly/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end

    context 'when disabling EPEL' do
      let :params do
        {
          :enable_epel => false,
        }
      end

      it { should_not contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}") }
    end

    context 'when using a proxy for yum repositories' do
      let :params do
        {
          :proxy => 'http://someproxy.com:8080/',
          :proxy_username => 'proxyuser',
          :proxy_password => 'proxypassword'
        }
      end

      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure         => 'present',
        :descr          => "External EPEL #{facts[:os]['release']['major']}",
        :name           => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl        => 'absent',
        :gpgcheck       => '1',
        :gpgkey         => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist     => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority       => '20',
        :exclude        => 'python3-rbd python3-rados python3-cephfs',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure         => 'present',
        :descr          => 'External Ceph nautilus',
        :name           => 'ext-ceph-nautilus',
        :baseurl        => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck       => '1',
        :gpgkey         => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist     => 'absent',
        :priority       => '10',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure         => 'present',
        :descr          => 'External Ceph noarch',
        :name           => 'ext-ceph-nautilus-noarch',
        :baseurl        => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck       => '1',
        :gpgkey         => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist     => 'absent',
        :priority       => '10',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
      )}
    end

    context 'with ensure => absent to disable' do
      let :params do
        {
          :ensure  => 'absent',
        }
      end

      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure     => 'absent',
        :descr      => "External EPEL #{facts[:os]['release']['major']}",
        :name       => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority   => '20',
        :exclude    => 'python3-rbd python3-rados python3-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure     => 'absent',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure     => 'absent',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end
  end

  shared_examples 'ceph::repo on CentOS' do
    context 'with default params' do
      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure     => 'present',
        :descr      => "External EPEL #{facts[:os]['release']['major']}",
        :name       => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority   => '20',
        :exclude    => 'python3-rbd python3-rados python3-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure     => 'present',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure     => 'present',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end

    context 'when overriding ceph release' do
      let :params do
        {
          :release => 'firefly'
        }
      end

      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure     => 'present',
        :descr      => "External EPEL #{facts[:os]['release']['major']}",
        :name       => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority   => '20',
        :exclude    => 'python3-rbd python3-rados python3-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure     => 'present',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => "http://download.ceph.com/rpm-firefly/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure     => 'present',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => "http://download.ceph.com/rpm-firefly/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end

    context 'when using CentOS SIG repository' do
      let :params do
        {
          :enable_sig  => true,
          :enable_epel => false,
        }
      end

      it { should_not contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}") }
      it { should_not contain_yumrepo('ext-ceph') }
      it { should_not contain_yumrepo('ext-ceph-noarch') }


      it { should contain_yumrepo('ceph-storage-sig').with(
        :baseurl => "#{platform_params[:centos_mirror]}/#{facts[:os]['release']['major']}-stream/storage/x86_64/ceph-nautilus/",
      )}
    end

    context 'when using CentOS SIG repository from a mirror' do
      let :params do
        {
          :enable_sig  => true,
          :enable_epel => false,
          :ceph_mirror => 'https://mymirror/luminous/',
        }
      end

      it { should_not contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}") }
      it { should_not contain_yumrepo('ext-ceph') }
      it { should_not contain_yumrepo('ext-ceph-noarch') }

      it { should contain_yumrepo('ceph-storage-sig').with(
        :baseurl => 'https://mymirror/luminous/',
      )}
    end

    context 'with ensure => absent to disable' do
      let :params do
        {
          :ensure  => 'absent',
        }
      end

      it { should contain_yumrepo("ext-epel-#{facts[:os]['release']['major']}").with(
        :ensure     => 'absent',
        :descr      => "External EPEL #{facts[:os]['release']['major']}",
        :name       => "ext-epel-#{facts[:os]['release']['major']}",
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-#{facts[:os]['release']['major']}",
        :mirrorlist => "http://mirrors.fedoraproject.org/metalink?repo=epel-#{facts[:os]['release']['major']}&arch=$basearch",
        :priority   => '20',
        :exclude    => 'python3-rbd python3-rados python3-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :ensure     => 'absent',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/$basearch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :ensure     => 'absent',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => "http://download.ceph.com/rpm-nautilus/el#{facts[:os]['release']['major']}/noarch",
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like "ceph::repo on #{facts[:os]['family']}"

      if facts[:os]['name'] == 'CentOS'
        let (:platform_params) do
          { :centos_mirror => 'https://mirror.stream.centos.org/SIGs' }
        end
        it_behaves_like 'ceph::repo on CentOS'
      end
    end
  end
end
