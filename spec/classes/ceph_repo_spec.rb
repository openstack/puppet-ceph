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
# Author: François Charlier <francois.charlier@enovance.com>
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: Andrew Woodward <xarses>

require 'spec_helper'

describe 'ceph::repo' do

  describe 'Debian' do

    let :facts do
    {
      :osfamily         => 'Debian',
      :lsbdistcodename  => 'wheezy'
    }
    end

    describe "with default params" do

      it { should contain_apt__key('ceph').with(
        :key        => '17ED316D',
        :key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
      ) }

      it { should contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-firefly/',
        :release  => 'wheezy',
        :require  => 'Apt::Key[ceph]'
      ) }

    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'dumpling'
        }
      end

      it { should contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-dumpling/',
        :release  => 'wheezy',
        :require  => 'Apt::Key[ceph]'
      ) }
    end

  end

  describe 'Ubuntu' do

    let :facts do
    {
      :osfamily         => 'Debian',
      :lsbdistcodename  => 'precise'
    }
    end

    describe "with default params" do

      it { should contain_apt__key('ceph').with(
        :key        => '17ED316D',
        :key_source => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc'
      ) }

      it { should contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-firefly/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
      ) }

    end

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'dumpling'
        }
      end

      it { should contain_apt__source('ceph').with(
        :location => 'http://ceph.com/debian-dumpling/',
        :release  => 'precise',
        :require  => 'Apt::Key[ceph]'
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

      it { should contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { should contain_yumrepo('ext-ceph-noarch').with(
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

    describe "when overriding ceph release" do
      let :params do
        {
         :release => 'dumpling'
        }
      end

      it { should contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '1',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '1',
        :descr      => 'External Ceph dumpling',
        :name       => 'ext-ceph-dumpling',
        :baseurl    => 'http://ceph.com/rpm-dumpling/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '1',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-dumpling-noarch',
        :baseurl    => 'http://ceph.com/rpm-dumpling/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end

    describe "with ensure => absent to disable" do
      let :params do
        {
          :ensure => 'absent'
        }
      end

      it { should contain_yumrepo('ext-epel-6.8').with(
        :enabled    => '0',
        :descr      => 'External EPEL 6.8',
        :name       => 'ext-epel-6.8',
        :baseurl    => 'absent',
        :gpgcheck   => '0',
        :gpgkey     => 'absent',
        :mirrorlist => 'https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch',
        :priority   => '20'
      ) }

      it { should contain_yumrepo('ext-ceph').with(
        :enabled    => '0',
        :descr      => 'External Ceph firefly',
        :name       => 'ext-ceph-firefly',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/$basearch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
     ) }

      it { should contain_yumrepo('ext-ceph-noarch').with(
        :enabled    => '0',
        :descr      => 'External Ceph noarch',
        :name       => 'ext-ceph-firefly-noarch',
        :baseurl    => 'http://ceph.com/rpm-firefly/el6/noarch',
        :gpgcheck   => '1',
        :gpgkey     => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
        :mirrorlist => 'absent',
        :priority   => '10'
      ) }
    end


  end

end
