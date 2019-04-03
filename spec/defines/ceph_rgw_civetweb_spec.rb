#
# Copyright (C) 2016 Keith Schincke
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
# Author: Keith Schincke <keith.schincke@gmail.com>
#
require 'spec_helper'

describe 'ceph::rgw' do
  let :pre_condition do
    'include ceph::params'
  end

  shared_examples 'ceph rgw civetweb' do
    describe "activated with civetweb params" do
      let :title do
        'radosgw.civetweb'
      end

      let :params do
      {
        :frontend_type => 'civetweb',
      }
      end

      it { should contain_ceph_config('client.radosgw.civetweb/user').with_value("#{platform_params[:user]}") }
      it { should contain_ceph_config('client.radosgw.civetweb/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.civetweb/keyring').with_value('/etc/ceph/ceph.client.radosgw.civetweb.keyring') }
      it { should contain_ceph_config('client.radosgw.civetweb/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { should contain_ceph_config('client.radosgw.civetweb/rgw_frontends').with_value('civetweb port=7480') }
      it { should contain_ceph_config('client.radosgw.civetweb/rgw_dns_name').with_value('myhost.domain') }
      it { should contain_ceph_config('client.radosgw.civetweb/rgw_swift_url').with_value('http://myhost.domain:7480') }
    end

    describe "activated with custom civetweb params" do
      let :title do
        'radosgw.custom'
      end

      let :params do
      {
        :frontend_type => 'civetweb',
        :rgw_frontends => 'civetweb port=7481',
        :user          => 'root',
        :rgw_dns_name  => 'mydns.hostname',
        :rgw_swift_url => 'https://mydns.hostname:443'
      }
      end

      it { should contain_ceph_config('client.radosgw.custom/rgw_frontends').with_value('civetweb port=7481') }
      it { should contain_ceph_config('client.radosgw.custom/user').with_value('root') }
      it { should contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
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
        facts.merge!(OSDefaults.get_facts({
          :concat_basedir         => '/var/lib/puppet/concat',
          :fqdn                   => 'myhost.domain',
          :hostname               => 'myhost',
        }))
      end

      let :platform_params do
        case facts[:osfamily]
        when 'Debian'
          {
            :pkg_radosgw => 'radosgw',
            :user        => 'www-data',
          }
        when 'RedHat'
          {
            :pkg_radosgw => 'ceph-radosgw',
            :user        => 'apache',
          }
        end
      end

      it_behaves_like 'ceph rgw civetweb'
    end
  end
end
