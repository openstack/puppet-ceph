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

describe 'ceph' do

  shared_examples_for 'ceph' do
    describe "with default params and specified fsid" do
      let :params do
        {
          :fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b',
        }
      end

      it { is_expected.to contain_package('ceph').with(
      'name'   => 'ceph',
      'ensure' => 'present') }

      it { is_expected.to contain_ceph_config('global/fsid').with_value('d5252e7d-75bc-4083-85ed-fe51fa83f62b') }
      it { is_expected.to_not contain_ceph_config('global/keyring').with_value('/etc/ceph/keyring') }
      it { is_expected.to_not contain_ceph_config('global/osd_pool_default_pg_num').with_value('128') }
      it { is_expected.to_not contain_ceph_config('global/osd_pool_default_pgp_num').with_value('128') }
      it { is_expected.to_not contain_ceph_config('global/osd_pool_default_size').with_value('3') }
      it { is_expected.to_not contain_ceph_config('global/osd_pool_default_min_size').with_value('2') }
      it { is_expected.to_not contain_ceph_config('global/osd_pool_default_crush_rule').with_value('0') }
      it { is_expected.to_not contain_ceph_config('global/osd_crush_update_on_start').with_value(false) }
      it { is_expected.to_not contain_ceph_config('global/mon_osd_full_ratio').with_value('90') }
      it { is_expected.to_not contain_ceph_config('global/mon_osd_nearfull_ratio').with_value('85') }
      it { is_expected.to_not contain_ceph_config('global/mon_initial_members').with_value('mon.01') }
      it { is_expected.to_not contain_ceph_config('global/mon_host').with_value('mon01.ceph, mon02.ceph') }
      it { is_expected.to_not contain_ceph_config('global/ms_bind_ipv6').with_value('false') }
      it { is_expected.to_not contain_ceph_config('global/require_signatures').with_value('false') }
      it { is_expected.to_not contain_ceph_config('global/cluster_require_signatures').with_value('false') }
      it { is_expected.to_not contain_ceph_config('global/service_require_signatures').with_value('false') }
      it { is_expected.to_not contain_ceph_config('global/sign_messages').with_value('true') }
      it { is_expected.to_not contain_ceph_config('global/cluster_network').with_value('10.0.0.0/24') }
      it { is_expected.to_not contain_ceph_config('global/public_network').with_value('192.168.0.0/24') }
      it { is_expected.to_not contain_ceph_config('global/public_addr').with_value('192.168.0.2') }
      it { is_expected.to_not contain_ceph_config('osd/osd_journal_size').with_value('4096') }
      it { is_expected.to_not contain_ceph_config('client/rbd_default_features').with_value('15') }
      it { is_expected.to contain_ceph_config('global/auth_cluster_required').with_value('cephx') }
      it { is_expected.to contain_ceph_config('global/auth_service_required').with_value('cephx') }
      it { is_expected.to contain_ceph_config('global/auth_client_required').with_value('cephx') }
      it { is_expected.to contain_ceph_config('global/auth_supported').with_value('cephx') }
      it { is_expected.to_not contain_ceph_config('global/auth_cluster_required').with_value('none') }
      it { is_expected.to_not contain_ceph_config('global/auth_service_required').with_value('none') }
      it { is_expected.to_not contain_ceph_config('global/auth_client_required').with_value('none') }
      it { is_expected.to_not contain_ceph_config('global/auth_supported').with_value('none') }
    end

    describe "with custom params and specified fsid" do
      let :params do
        {
          :fsid                          => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b',
          :authentication_type           => 'none',
          :keyring                       => '/usr/local/ceph/etc/keyring',
          :osd_journal_size              => '1024',
          :osd_max_object_name_len       => '1024',
          :osd_max_object_namespace_len  => '256',
          :osd_pool_default_pg_num       => '256',
          :osd_pool_default_pgp_num      => '256',
          :osd_pool_default_size         => '2',
          :osd_pool_default_min_size     => '1',
          :osd_pool_default_crush_rule   => '10',
          :osd_crush_update_on_start     => false,
          :mon_osd_full_ratio            => '95',
          :mon_osd_nearfull_ratio        => '90',
          :mon_initial_members           => 'mon.01',
          :mon_host                      => 'mon01.ceph, mon02.ceph',
          :ms_bind_ipv6                  => 'true',
          :require_signatures            => 'true',
          :cluster_require_signatures    => 'true',
          :service_require_signatures    => 'true',
          :sign_messages                 => 'false',
          :cluster_network               => '10.0.0.0/24',
          :public_network                => '192.168.0.0/24',
          :public_addr                   => '192.168.0.2',
          :set_osd_params                => 'true',
          :osd_max_backfills             => '1',
          :osd_recovery_max_active       => '1',
          :osd_recovery_op_priority      => '1',
          :osd_recovery_max_single_start => '1',
          :osd_max_scrubs                => '1',
          :osd_op_threads                => '2',
          :rbd_default_features          => '12',
        }
      end

      it { is_expected.to contain_package('ceph').with(
      'name'   => 'ceph',
      'ensure' => 'present') }

      it { is_expected.to contain_ceph_config('global/fsid').with_value('d5252e7d-75bc-4083-85ed-fe51fa83f62b') }
      it { is_expected.to contain_ceph_config('global/keyring').with_value('/usr/local/ceph/etc/keyring') }
      it { is_expected.to contain_ceph_config('global/osd_max_object_name_len').with_value('1024') }
      it { is_expected.to contain_ceph_config('global/osd_max_object_namespace_len').with_value('256') }
      it { is_expected.to contain_ceph_config('global/osd_pool_default_pg_num').with_value('256') }
      it { is_expected.to contain_ceph_config('global/osd_pool_default_pgp_num').with_value('256') }
      it { is_expected.to contain_ceph_config('global/osd_pool_default_size').with_value('2') }
      it { is_expected.to contain_ceph_config('global/osd_pool_default_min_size').with_value('1') }
      it { is_expected.to contain_ceph_config('global/osd_pool_default_crush_rule').with_value('10') }
      it { is_expected.to contain_ceph_config('global/osd_crush_update_on_start').with_value(false) }
      it { is_expected.to contain_ceph_config('global/mon_osd_full_ratio').with_value('95') }
      it { is_expected.to contain_ceph_config('global/mon_osd_nearfull_ratio').with_value('90') }
      it { is_expected.to contain_ceph_config('global/mon_initial_members').with_value('mon.01') }
      it { is_expected.to contain_ceph_config('global/mon_host').with_value('mon01.ceph, mon02.ceph') }
      it { is_expected.to contain_ceph_config('global/ms_bind_ipv6').with_value('true') }
      it { is_expected.to contain_ceph_config('global/require_signatures').with_value('true') }
      it { is_expected.to contain_ceph_config('global/cluster_require_signatures').with_value('true') }
      it { is_expected.to contain_ceph_config('global/service_require_signatures').with_value('true') }
      it { is_expected.to contain_ceph_config('global/sign_messages').with_value('false') }
      it { is_expected.to contain_ceph_config('global/cluster_network').with_value('10.0.0.0/24') }
      it { is_expected.to contain_ceph_config('global/public_network').with_value('192.168.0.0/24') }
      it { is_expected.to contain_ceph_config('global/public_addr').with_value('192.168.0.2') }
      it { is_expected.to contain_ceph_config('osd/osd_journal_size').with_value('1024') }
      it { is_expected.to contain_ceph_config('client/rbd_default_features').with_value('12') }
      it { is_expected.to_not contain_ceph_config('global/auth_cluster_required').with_value('cephx') }
      it { is_expected.to_not contain_ceph_config('global/auth_service_required').with_value('cephx') }
      it { is_expected.to_not contain_ceph_config('global/auth_client_required').with_value('cephx') }
      it { is_expected.to_not contain_ceph_config('global/auth_supported').with_value('cephx') }
      it { is_expected.to contain_ceph_config('global/auth_cluster_required').with_value('none') }
      it { is_expected.to contain_ceph_config('global/auth_service_required').with_value('none') }
      it { is_expected.to contain_ceph_config('global/auth_client_required').with_value('none') }
      it { is_expected.to contain_ceph_config('global/auth_supported').with_value('none') }
      it { is_expected.to contain_ceph_config('osd/osd_max_backfills').with_value('1') }
      it { is_expected.to contain_ceph_config('osd/osd_recovery_max_active').with_value('1') }
      it { is_expected.to contain_ceph_config('osd/osd_recovery_op_priority').with_value('1') }
      it { is_expected.to contain_ceph_config('osd/osd_recovery_max_single_start').with_value('1') }
      it { is_expected.to contain_ceph_config('osd/osd_max_scrubs').with_value('1') }
      it { is_expected.to contain_ceph_config('osd/osd_op_threads').with_value('2') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph'
    end
  end

end
