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
        :key        => '17ED316D',
        :key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-giant/',
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
        :key        => '17ED316D',
        :key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-giant/',
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
        :location => 'http://ceph.com/debian-giant/',
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
        :key        => '6EAEAE2203C3951A',
        :key_server => 'keyserver.ubuntu.com'
      ) }

      it { is_expected.to contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-giant/',
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
        :location => 'http://ceph.com/debian-giant/',
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
      :osfamily         => 'RedHat',
    }
    end

    describe "with default params" do

      it { is_expected.to contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph giant',
        :name       => 'ext-ceph-giant',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-giant-noarch',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
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

      it { is_expected.to contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
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

      it { is_expected.to contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '0',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph giant',
        :name       => 'ext-ceph-giant',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-giant-noarch',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-extras').with(
        :enabled    => '0',
        :descr      => 'External Ceph Extras',
        :name       => 'ext-ceph-extras',
        :baseurl    => 'http://ceph.com/packages/ceph-extras/rpm/rhel6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
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

      it { is_expected.to contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph giant',
        :name       => 'ext-ceph-giant',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-giant-noarch',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph-extras').with(
        :enabled    => '1',
        :descr      => 'External Ceph Extras',
        :name       => 'ext-ceph-extras',
        :baseurl    => 'http://ceph.com/packages/ceph-extras/rpm/rhel6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
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

      it { is_expected.to contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'http://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { is_expected.to contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph giant',
        :name       => 'ext-ceph-giant',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { is_expected.to contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-giant-noarch',
        :baseurl    => 'http://ceph.com/rpm-giant/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
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

end
