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

  describe 'Debian' do

    let :facts do
    {
      :osfamily        => 'Debian',
      :lsbdistid       => 'Debian',
      :lsbdistcodename => 'jessie',
      :lsbdistrelease  => '8',
    }
    end

    describe "with default params" do

      it { is_expected.to contain_apt__key('ceph').with(
        :id     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :source => 'https://download.ceph.com/keys/release.asc',
        :before => 'Apt::Source[ceph]',
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-jewel/',
        :release  => 'jessie',
      ) }

    end

    describe "when overriding ceph mirror" do
      let :params do
        {
         :ceph_mirror => 'http://myserver.com/debian-jewel/'
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://myserver.com/debian-jewel/',
        :release  => 'jessie',
      ) }
    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'firefly'
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-firefly/',
        :release  => 'jessie',
      ) }
    end

  end

  describe 'Ubuntu' do

    let :facts do
    {
      :osfamily        => 'Debian',
      :lsbdistid       => 'Ubuntu',
      :lsbdistcodename => 'trusty',
      :lsbdistrelease  => '14.04',
      :hardwaremodel   => 'x86_64',
    }
    end

    describe "with default params" do

      it { is_expected.to contain_apt__key('ceph').with(
        :id     => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :source => 'https://download.ceph.com/keys/release.asc',
        :before => 'Apt::Source[ceph]',
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-jewel/',
        :release  => 'trusty',
      ) }

    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'firefly'
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-firefly/',
        :release  => 'trusty',
      ) }
    end

    describe "when wanting fast-cgi" do
      let :params do
        {
         :fastcgi => true
        }
      end

      it { is_expected.to contain_apt__key('ceph-gitbuilder').with(
        :id     => 'FCC5CB2ED8E6F6FB79D5B3316EAEAE2203C3951A',
        :server => 'keyserver.ubuntu.com',
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://download.ceph.com/debian-jewel/',
        :release  => 'trusty',
      ) }

      it { is_expected.to contain_apt__source('ceph-fastcgi').with(
        :ensure   => 'present',
        :location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-trusty-x86_64-basic/ref/master',
        :release  => 'trusty',
        :require  => 'Apt::Key[ceph-gitbuilder]'
      ) }

    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure  => 'absent',
          :fastcgi => true
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :ensure   => 'absent',
        :location => 'http://download.ceph.com/debian-jewel/',
        :release  => 'trusty',
      ) }

      it { is_expected.to contain_apt__source('ceph-fastcgi').with(
        :ensure   => 'absent',
        :location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-trusty-x86_64-basic/ref/master',
        :release  => 'trusty',
        :require  => 'Apt::Key[ceph-gitbuilder]'
      ) }

    end

  end

  describe 'RHEL7' do

    let :facts do
    {
      :osfamily                  => 'RedHat',
      :operatingsystem           => 'RedHat',
      :operatingsystemmajrelease => '7',
    }
    end

    describe "with default params" do

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph jewel',
        :name       => 'ext-ceph-jewel',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-jewel-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'firefly'
        }
      end

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "when disabling EPEL" do
      let :params do
        {
         :enable_epel => false,
        }
      end

      it { is_expected.to_not contain_yumrepo('ext-epel-7') }
    end

    describe "when using a proxy for yum repositories" do
      let :params do
        {
         :proxy => 'http://someproxy.com:8080/',
         :proxy_username => 'proxyuser',
         :proxy_password => 'proxypassword'
        }
      end

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
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
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled        => '1',
        :descr          => 'External Ceph jewel',
        :name           => 'ext-ceph-jewel',
        :baseurl        => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck       => '1',
        :gpgkey         => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist     => 'absent',
        :priority       => '10',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled        => '1',
        :descr          => 'External Ceph noarch',
        :name           => 'ext-ceph-jewel-noarch',
        :baseurl        => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck       => '1',
        :gpgkey         => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist     => 'absent',
        :priority       => '10',
        :proxy          => 'http://someproxy.com:8080/',
        :proxy_username => 'proxyuser',
        :proxy_password => 'proxypassword',
      ) }
    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure  => 'absent',
          :fastcgi => true
        }
      end

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '0',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph jewel',
        :name       => 'ext-ceph-jewel',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-jewel-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '0',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end

    describe "with ceph fast-cgi" do
      let :params do
        {
          :fastcgi => true
        }
      end

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph jewel',
        :name       => 'ext-ceph-jewel',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-jewel-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '1',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end
  end

  describe 'CentOS7' do

    let :facts do
    {
      :osfamily                  => 'RedHat',
      :operatingsystem           => 'CentOS',
      :operatingsystemmajrelease => '7',
    }
    end

    describe "with default params" do

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph jewel',
        :name       => 'ext-ceph-jewel',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-jewel-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'firefly'
        }
      end

      it { is_expected.to contain_file_line('exclude base').with(
        :ensure => 'present',
        :path   => '/etc/yum.repos.d/CentOS-Base.repo',
        :after  => '^\[base\]$',
        :line   => 'exclude=python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-firefly/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "when using CentOS SIG repository" do
      let :params do
        {
         :enable_sig => true,
        }
      end

      it { is_expected.to_not contain_file_line('exclude base') }
      it { is_expected.to_not contain_yumrepo('ext-epel-7') }
      it { is_expected.to_not contain_yumrepo('ext-ceph') }
      it { is_expected.to_not contain_yumrepo('ext-ceph-noarch') }
      it { is_expected.to contain_yumrepo('ceph-jewel-sig') }
    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure  => 'absent',
          :fastcgi => true
        }
      end

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '0',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph jewel',
        :name       => 'ext-ceph-jewel',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-jewel-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '0',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end

    describe "with ceph fast-cgi" do
      let :params do
        {
          :fastcgi => true
        }
      end

      it { is_expected.not_to contain_file_line('exclude base') }

      it { is_expected.to contain_yumrepo('ext-epel-7').with(
        :enabled    => '1',
        :descr      => 'External EPEL 7',
        :name       => 'ext-epel-7',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph jewel',
        :name       => 'ext-ceph-jewel',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-jewel-noarch',
        :baseurl    => 'http://download.ceph.com/rpm-jewel/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '1',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://download.ceph.com/keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end
  end

end
