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

describe 'ceph::rgw' do
  let :pre_condition do
    'include ceph::params'
  end
  shared_examples 'ceph rgw beast' do
    describe "activated with beast params" do
      let :title do
        'radosgw.beast'
      end

      let :params do
      {
        :frontend_type => 'beast',
      }
      end

      it { should contain_ceph_config('client.radosgw.beast/user').with_value("#{platform_params[:user]}") }
      it { should contain_ceph_config('client.radosgw.beast/host').with_value('foo') }
      it { should contain_ceph_config('client.radosgw.beast/keyring').with_value('/etc/ceph/ceph.client.radosgw.beast.keyring') }
      it { should contain_ceph_config('client.radosgw.beast/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { should contain_ceph_config('client.radosgw.beast/rgw_frontends').with_value('beast port=7480') }
      it { should contain_ceph_config('client.radosgw.beast/rgw_dns_name').with_value('foo.example.com') }
      it { should contain_ceph_config('client.radosgw.beast/rgw_swift_url').with_value('http://foo.example.com:7480') }
    end

    describe "activated with custom beast params" do
      let :title do
        'radosgw.custom'
      end

      let :params do
      {
        :frontend_type => 'beast',
        :rgw_frontends => 'beast endpoint=0.0.0.0:8080 port=8080',
        :user          => 'root',
        :rgw_dns_name  => 'mydns.hostname',
        :rgw_swift_url => 'https://mydns.hostname:443'
      }
      end

      it { should contain_ceph_config('client.radosgw.custom/rgw_frontends').with_value('beast endpoint=0.0.0.0:8080 port=8080') }
      it { should contain_ceph_config('client.radosgw.custom/user').with_value('root') }
      it { should contain_ceph_config('client.radosgw.custom/host').with_value('foo') }
      it { should contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.client.radosgw.custom.keyring') }
      it { should contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_dns_name').with_value('mydns.hostname') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_swift_url').with_value('https://mydns.hostname:443') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      let :platform_params do
        case facts[:os]['family']
        when 'Debian'
          {
            :user => 'www-data',
          }
        when 'RedHat'
          {
            :user => 'apache',
          }
        end
      end

      it_behaves_like 'ceph rgw beast'
    end
  end
end
