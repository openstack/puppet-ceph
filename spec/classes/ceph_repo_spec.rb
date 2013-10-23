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
        :location => 'http://ceph.com/debian-cuttlefish/',
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
        :location => 'http://ceph.com/debian-cuttlefish/',
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

end