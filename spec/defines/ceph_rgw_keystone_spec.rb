#
# Copyright (C) 2014 Catalyst IT Limited.
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
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#

require 'spec_helper'

describe 'ceph::rgw::keystone' do
  shared_examples 'ceph::rgw::keystone' do
    context 'create with default params' do
      let :pre_condition do
        "include ceph::params
         class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
         class { 'ceph::repo': }
         include ceph
         ceph::rgw { 'radosgw.gateway': }"
      end

      let :title do
        'radosgw.gateway'
      end

      let :params do
        {
          :rgw_keystone_admin_domain   => 'default',
          :rgw_keystone_admin_project  => 'openstack',
          :rgw_keystone_admin_user     => 'rgwuser',
          :rgw_keystone_admin_password => '123456',
        }
      end

      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_api_version').with_value(3) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_domain').with_value('default') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_project').with_value('openstack') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_user').with_value('rgwuser') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_password').with_value('123456') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_url').with_value('http://127.0.0.1:5000') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_accepted_roles').with_value('member') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_token_cache_size').with_value(500) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_s3_auth_use_keystone').with_value(true) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_implicit_tenants').with_value(true) }
    end

    context 'create with custom params' do
      let :pre_condition do
        "include ceph::params
         class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
         class { 'ceph::repo': }
         ceph::rgw { 'radosgw.custom': }"
      end

      let :title do
        'radosgw.custom'
      end

      let :params do
        {
          :rgw_keystone_admin_domain     => 'default',
          :rgw_keystone_admin_project    => 'openstack',
          :rgw_keystone_admin_user       => 'rgwuser',
          :rgw_keystone_admin_password   => '123456',
          :rgw_keystone_url              => 'http://keystone.custom:5000',
          :rgw_keystone_accepted_roles   => '_role1_,role2',
          :rgw_keystone_token_cache_size => 100,
          :rgw_s3_auth_use_keystone      => false,
          :rgw_keystone_implicit_tenants => false,
        }
      end

      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_api_version').with_value(3) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_domain').with_value('default') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_project').with_value('openstack') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_user').with_value('rgwuser') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_password').with_value('123456') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_url').with_value('http://keystone.custom:5000') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_accepted_roles').with_value('_role1_,role2') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_token_cache_size').with_value(100) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_s3_auth_use_keystone').with_value(false) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_implicit_tenants').with_value(false) }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::rgw::keystone'
    end
  end
end
