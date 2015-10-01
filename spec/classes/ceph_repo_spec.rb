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
      :lsbdistcodename => 'wheezy',
    }
    end

    describe "with default params" do

      it { is_expected.to contain_apt__key('ceph').with(
        :key        => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :key_source => 'https://git.ceph.com/release.asc'
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-hammer/',
        :release  => 'wheezy',
        :require  => 'Apt::Key[ceph]'
      ) }

    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'firefly'
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-firefly/',
        :release  => 'wheezy',
        :require  => 'Apt::Key[ceph]'
      ) }
    end

  end

  describe 'Ubuntu' do

    let :facts do
    {
      :osfamily        => 'Debian',
      :lsbdistcodename => 'precise',
      :hardwaremodel   => 'x86_64',
    }
    end

    describe "with default params" do

      it { is_expected.to contain_apt__key('ceph').with(
        :key        => '08B73419AC32B4E966C1A330E84AC2C0460F3994',
        :key_source => 'https://git.ceph.com/release.asc'
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-hammer/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'firefly'
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-firefly/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }
    end

    describe "when wanting extras" do
      let :params do
        {
         :extras => true
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-hammer/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

      it { is_expected.to contain_apt__source('ceph-extras').with(
        :ensure   => 'present',
        :location => 'http://ceph.com/packages/ceph-extras/debian/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

    end

    describe "when wanting fast-cgi" do
      let :params do
        {
         :fastcgi => true
        }
      end

      it { is_expected.to contain_apt__key('ceph-gitbuilder').with(
        :key        => 'FCC5CB2ED8E6F6FB79D5B3316EAEAE2203C3951A',
        :key_server => 'keyserver.ubuntu.com'
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-hammer/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

      it { is_expected.to contain_apt__source('ceph-fastcgi').with(
        :ensure   => 'present',
        :location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-precise-x86_64-basic/ref/master',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph-gitbuilder]'
      ) }

    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure  => 'absent',
          :extras  => true,
          :fastcgi => true
        }
      end

      it { is_expected.to contain_apt__source('ceph').with(
        :ensure   => 'absent',
        :location => 'http://ceph.com/debian-hammer/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

      it { is_expected.to contain_apt__source('ceph-extras').with(
        :ensure   => 'absent',
        :location => 'http://ceph.com/packages/ceph-extras/debian/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

      it { is_expected.to contain_apt__source('ceph-fastcgi').with(
        :ensure   => 'absent',
        :location => 'http://gitbuilder.ceph.com/libapache-mod-fastcgi-deb-precise-x86_64-basic/ref/master',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph-gitbuilder]'
      ) }

    end

  end

  describe 'RHEL6' do

    let :facts do
    {
      :osfamily                  => 'RedHat',
      :operatingsystem           => 'RedHat',
      :operatingsystemmajrelease => '6',
    }
    end

    describe "with default params" do

      it { is_expected.to contain_yumrepo('ext-epel-6').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6',
        :name       => 'ext-epel-6',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
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

      it { is_expected.to contain_yumrepo('ext-epel-6').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6',
        :name       => 'ext-epel-6',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure  => 'absent',
          :extras  => true,
          :fastcgi => true
        }
      end

      it { is_expected.to contain_yumrepo('ext-epel-6').with(
        :enabled    => '0',
        :descr      => 'External EPEL 6',
        :name       => 'ext-epel-6',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-extras').with(
        :enabled    => '0',
        :descr      => 'External Ceph Extras',
        :name       => 'ext-ceph-extras',
        :baseurl    => 'http://ceph.com/packages/ceph-extras/rpm/rhel6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '0',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel6-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end

    describe "with ceph extras" do
      let :params do
        {
          :extras => true
        }
      end

      it { is_expected.to contain_yumrepo('ext-epel-6').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6',
        :name       => 'ext-epel-6',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-extras').with(
        :enabled    => '1',
        :descr      => 'External Ceph Extras',
        :name       => 'ext-ceph-extras',
        :baseurl    => 'http://ceph.com/packages/ceph-extras/rpm/rhel6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

    end

    describe "with ceph fast-cgi" do
      let :params do
        {
          :fastcgi => true
        }
      end

      it { is_expected.to contain_yumrepo('ext-epel-6').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6',
        :name       => 'ext-epel-6',
        :baseurl    => 'absent',
        :gpgcheck   => '1',
        :gpgkey     => 'https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20',
        :exclude    => 'python-ceph-compat python-rbd python-rados python-cephfs',
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '1',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel6-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
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
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
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
        :baseurl    => 'http://ceph.com/rpm-firefly/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://ceph.com/rpm-firefly/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure  => 'absent',
          :extras  => true,
          :fastcgi => true
        }
      end

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
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to_not contain_yumrepo('ext-ceph-extras') }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '0',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end

    describe "with ceph extras" do
      let :params do
        {
          :extras => true
        }
      end

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
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to_not contain_yumrepo('ext-ceph-extras') }
    end

    describe "with ceph fast-cgi" do
      let :params do
        {
          :fastcgi => true
        }
      end

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
        :descr      => 'External Ceph hammer',
        :name       => 'ext-ceph-hammer',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-hammer-noarch',
        :baseurl    => 'http://ceph.com/rpm-hammer/el7/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://git.ceph.com/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-fastcgi').with(
        :enabled    => '1',
        :descr      => 'FastCGI basearch packages for Ceph',
        :name       => 'ext-ceph-fastcgi',
        :baseurl    => 'http://gitbuilder.ceph.com/mod_fastcgi-rpm-rhel7-x86_64-basic/ref/master',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/autobuild.asc',
        :mirrorlist => 'absent',
        :priority   => '20'
      ) }

    end
  end

end
