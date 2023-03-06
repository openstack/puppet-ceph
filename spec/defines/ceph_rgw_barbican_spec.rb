#
# Copyright (C) 2022 Red Hat
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
# Author: Takashi Kajinami <tkajinam@redhat.com>
#

require 'spec_helper'

describe 'ceph::rgw::barbican' do
  shared_examples 'ceph::rgw::barbican' do
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
          :rgw_keystone_barbican_domain   => 'default',
          :rgw_keystone_barbican_project  => 'openstack',
          :rgw_keystone_barbican_user     => 'rgwuser',
          :rgw_keystone_barbican_password => '123456',
        }
      end

      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_barbican_domain').with_value('default') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_barbican_project').with_value('openstack') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_barbican_user').with_value('rgwuser') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_keystone_barbican_password').with_value('123456').with_secret(true) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_barbican_url').with_value('http://127.0.0.1:9311') }
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
          :rgw_keystone_barbican_domain   => 'default',
          :rgw_keystone_barbican_project  => 'openstack',
          :rgw_keystone_barbican_user     => 'rgwuser',
          :rgw_keystone_barbican_password => '123456',
          :rgw_barbican_url               => 'http://barbican.custom:9311',
        }
      end

      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_barbican_domain').with_value('default') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_barbican_project').with_value('openstack') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_barbican_user').with_value('rgwuser') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_keystone_barbican_password').with_value('123456').with_secret(true) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_barbican_url').with_value('http://barbican.custom:9311') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::rgw::barbican'
    end
  end
end
