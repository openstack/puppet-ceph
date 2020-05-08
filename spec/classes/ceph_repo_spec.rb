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
    before do
      facts.merge!( :osfamily        => 'Debian',
                    :lsbdistid       => 'Debian',
                    :lsbdistcodename => 'jessie',
                    :lsbdistrelease  => '8' )
    end

    context 'with default params' do
      it { should contain_apt__key('ceph').with(
        :id     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :source => 'https://download.ceph.com/keys/release.asc',
        :before => 'Apt::Source[ceph]',
      )}

      it { should contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-nautilus/',
        :release  => 'jessie',
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
        :release  => 'jessie',
      )}
    end

    context 'when overriding ceph release' do
      let :params do
        {
          :release => 'firefly'
        }
      end

      it { should contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-firefly/',
        :release  => 'jessie',
      )}
    end
  end

  shared_examples 'ceph::repo on Ubuntu' do
    before do
      facts.merge!( :osfamily        => 'Debian',
                    :lsbdistid       => 'Ubuntu',
                    :lsbdistcodename => 'trusty',
                    :lsbdistrelease  => '14.04',
                    :hardwaremodel   => 'x86_64' )
    end

    context 'with default params' do
      it { should contain_apt__key('ceph').with(
        :id     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :source => 'https://download.ceph.com/keys/release.asc',
        :before => 'Apt::Source[ceph]',
      )}

      it { should contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-nautilus/',
        :release  => 'trusty',
      )}
    end

    context 'when overriding ceph release' do
      let :params do
        {
          :release => 'firefly'
        }
      end

      it { should contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-firefly/',
        :release  => 'trusty',
      )}
    end

    context 'when wanting fast-cgi' do
      let :params do
        {
          :fastcgi => true
        }
      end

      it { should contain_apt__key('ceph-gitbuilder').with(
        :id     => 'FCC5CB2ED8E6F6FB79D5B3316EAEAE2203C3951A',
        :server => 'keyserver.ubuntu.com',
      )}

      it { should contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-nautilus/',
        :release  => 'trusty',
      )}

      it { should contain_apt__source('ceph-fastcgi').with(
        :ensure   => 'present',
        :location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-trusty-x86_64-basic/ref/master',
        :release  => 'trusty',
        :require  => 'Apt::Key[ceph-gitbuilder]'
      )}
    end

    context 'with ensure => absent to disable' do
      let :params do
        {
          :ensure  => 'absent',
          :fastcgi => true
        }
      end

      it { should contain_apt__source('ceph').with(
        :ensure   => 'absent',
        :location => 'http://download.ceph.com/debian-nautilus/',
        :release  => 'trusty',
      )}

      it { should contain_apt__source('ceph-fastcgi').with(
        :ensure   => 'absent',
        :location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-trusty-x86_64-basic/ref/master',
        :release  => 'trusty',
        :require  => 'Apt::Key[ceph-gitbuilder]'
      )}
    end
  end

  shared_examples 'ceph::repo on RHEL' do
    before do
      facts.merge!( :osfamily                  => 'RedHat',
                    :operatingsystem           => 'RedHat',
                    :operatingsystemmajrelease => '7' )
    end

    context 'with default params' do
      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
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

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/noarch',
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

      it { should_not contain_yumrepo('ext-epel-7') }
    end

    context 'when using a proxy for yum repositories' do
      let :params do
        {
          :proxy => 'http://someproxy.com:8080/',
          :proxy_username => 'proxyuser',
          :proxy_password => 'proxypassword'
        }
      end

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled        => '1',
        :descr          => 'External EPEL 7',
        :name           => 'ext-epel-7',
        :baseurl        => 'absent',
        :gpgcheck       => '1',
        :gpgkey         => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist     => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority       => '20',
        :exclude        => 'python-ceph-compat python-rbd python-rados python-cephfs',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled        => '1',
        :descr          => 'External Ceph nautilus',
        :name           => 'ext-ceph-nautilus',
        :baseurl        => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck       => '1',
        :gpgkey         => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist     => 'absent',
        :priority       => '10',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled        => '1',
        :descr          => 'External Ceph noarch',
        :name           => 'ext-ceph-nautilus-noarch',
        :baseurl        => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
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
          :fastcgi => true
        }
      end

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '0',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '0',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      )}
    end

    context 'with ceph fast-cgi' do
      let :params do
        {
          :fastcgi => true
        }
      end

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '1',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      )}
    end
  end

  shared_examples 'ceph::repo on CentOS' do
    before do
      facts.merge!( :osfamily                  => 'RedHat',
                    :operatingsystem           => 'CentOS',
                    :operatingsystemmajrelease => '7' )
    end

    context 'with default params' do
      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
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

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}
    end

    context 'when using CentOS SIG repository' do
      let :params do
        {
          :enable_sig => true,
        }
      end

      it { should_not contain_yumrepo('ext-epel-7') }
      it { should_not contain_yumrepo('ext-ceph') }
      it { should_not contain_yumrepo('ext-ceph-noarch') }
      it { should contain_yumrepo('ceph-luminous-sig').with_ensure('absent') }

      it { should contain_yumrepo('ceph-storage-sig').with(
        :baseurl => 'http://mirror.centos.org/centos/7/storage/x86_64/ceph-nautilus/',
      )}
    end

    context 'when using CentOS SIG repository from a mirror' do
      let :params do
        {
          :enable_sig  => true,
          :ceph_mirror => 'https://mymirror/luminous/',
        }
      end

      it { should_not contain_yumrepo('ext-epel-7') }
      it { should_not contain_yumrepo('ext-ceph') }
      it { should_not contain_yumrepo('ext-ceph-noarch') }
      it { should contain_yumrepo('ceph-luminous-sig').with_ensure('absent') }

      it { should contain_yumrepo('ceph-storage-sig').with(
        :baseurl => 'https://mymirror/luminous/',
      )}
    end

    context 'with ensure => absent to disable' do
      let :params do
        {
          :ensure  => 'absent',
          :fastcgi => true
        }
      end

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '0',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '0',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      )}
    end

    context 'with ceph fast-cgi' do
      let :params do
        {
          :fastcgi => true
        }
      end

      it { should contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      )}

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph nautilus',
        :name       => 'ext-ceph-nautilus',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-nautilus-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-nautilus/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      )}

      it { should contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '1',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
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

      it_behaves_like "ceph::repo on #{facts[:operatingsystem]}"

      if facts[:operatingsystem] == 'CentOS'
        it_behaves_like 'ceph::repo on RHEL'
      end
    end
  end
end
