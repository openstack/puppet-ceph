#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>

require 'spec_helper'

describe 'ceph::mds' do

  shared_examples_for 'ceph mds' do
    describe "activated with default params" do

      it { is_expected.to contain_ceph_config('mds/mds_data').with_value('/var/lib/ceph/mds/$cluster-$id') }
      it { is_expected.to contain_ceph_config('mds/keyring').with_value('/var/lib/ceph/mds/$cluster-$id/keyring') }

    end

    describe "activated with custom params" do
      let :params do
        {
          :mds_data => '/usr/local/ceph/var/lib/mds/_cluster-_id',
          :keyring  => '/usr/local/ceph/var/lib/mds/_cluster-_id/keyring'
        }
      end

      it { is_expected.to contain_ceph_config('mds/mds_data').with_value('/usr/local/ceph/var/lib/mds/_cluster-_id') }
      it { is_expected.to contain_ceph_config('mds/keyring').with_value('/usr/local/ceph/var/lib/mds/_cluster-_id/keyring') }

    end

    describe "not activated" do
      let :params do
        {
          :mds_activate => false
        }
      end

      it { is_expected.to_not contain_ceph_config('mds/mds_data').with_value('/var/lib/ceph/mds/_cluster-_id') }
      it { is_expected.to_not contain_ceph_config('mds/keyring').with_value('/var/lib/ceph/mds/_cluster-_id/keyring') }
      it { is_expected.to contain_ceph_config('mds/mds_data').with_ensure('absent') }
      it { is_expected.to contain_ceph_config('mds/keyring').with_ensure('absent') }

    end
  end

  describe 'Debian Family' do
    let :facts do
      {
        :osfamily => 'Debian',
      }
    end

    it_configures 'ceph mds'
 end

  describe 'RedHat Family' do
    let :facts do
      {
        :osfamily => 'RedHat',
      }
    end

    it_configures 'ceph mds'
 end

end
