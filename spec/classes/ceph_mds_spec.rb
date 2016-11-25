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

      it { is_expected.to contain_ceph_config('mds/mds_data').with_value('/var/lib/ceph/mds/ceph-myhostname') }
      it { is_expected.to contain_ceph_config('mds/keyring').with_value('/var/lib/ceph/mds/ceph-myhostname/keyring') }
      it { is_expected.to contain_package('ceph-mds').with('ensure' => 'present') }
    end

    describe "activated with custom params" do
      let :params do
        {
          :public_addr => '1.2.3.4',
          :mds_id      => 'mymds',
          :mds_data    => '/usr/local/ceph/var/lib/mds/_cluster-_id',
          :keyring     => '/usr/local/ceph/var/lib/mds/_cluster-_id/keyring'
        }
      end

      it { is_expected.to contain_ceph_config('mds/mds_data').with_value('/usr/local/ceph/var/lib/mds/_cluster-_id') }
      it { is_expected.to contain_ceph_config('mds/keyring').with_value('/usr/local/ceph/var/lib/mds/_cluster-_id/keyring') }
      it { is_expected.to contain_package('ceph-mds').with('ensure' => 'present') }
      it {
        is_expected.to contain_service('ceph-mds@mymds').with('ensure' => 'running')
      }
      it { is_expected.to contain_ceph_config('mds.mymds/public_addr').with_value('1.2.3.4') }
      it { is_expected.to contain_file('/usr/local/ceph/var/lib/mds/_cluster-_id').with( {
        'ensure'                  => 'directory',
        'owner'                   => 'ceph',
        'group'                   => 'ceph',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      } ) }
    end

    describe "not activated" do
      let :params do
        {
          :mds_activate => false
        }
      end

      it { is_expected.to contain_ceph_config('mds/mds_data').with_ensure('absent') }
      it { is_expected.to contain_ceph_config('mds/keyring').with_ensure('absent') }

    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({:hostname => 'myhostname'}))
      end

      it_behaves_like 'ceph mds'
    end
  end

end
