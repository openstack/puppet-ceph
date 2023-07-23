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

describe 'ceph::rgw' do
  let :pre_condition do
    'include ceph::params'
  end

  shared_examples 'ceph::rgw' do
    context 'activated with default params' do
      let :title do
        'radosgw.gateway'
      end

      it { should contain_package(platform_params[:pkg_radosgw]).with('ensure' => 'installed') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_enable_apis').with_ensure('absent') }
      it { should contain_ceph_config('client.radosgw.gateway/user').with_value(platform_params[:user]) }
      it { should contain_ceph_config('client.radosgw.gateway/host').with_value('foo') }
      it { should contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { should contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_dns_name').with_value('foo.example.com') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_swift_url').with_value('http://foo.example.com:7480') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_swift_url_prefix').with_value('swift') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_swift_account_in_url').with_value(false) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_swift_versioning_enabled').with_value(false) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_trust_forwarded_https').with_value(false) }

      it { should contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway').with(
        :ensure                  => 'directory',
        :owner                   => 'root',
        :group                   => 'root',
        :mode                    => '0750',
        :selinux_ignore_defaults => true,
      )}

      it { should contain_service('radosgw-radosgw.gateway') }
    end

    context 'activated with custom params' do
      let :title do
        'radosgw.custom'
      end

      let :params do
        {
          :pkg_radosgw                  => 'pkgradosgw',
          :rgw_ensure                   => 'stopped',
          :rgw_enable                   => false,
          :rgw_enable_apis              => ['s3', 'swift'],
          :rgw_data                     => '/var/lib/ceph/radosgw/ceph-radosgw.custom',
          :user                         => 'wwwuser',
          :keyring_path                 => '/etc/ceph/ceph.radosgw.custom.keyring',
          :log_file                     => '/var/log/ceph/mylogfile.log',
          :rgw_dns_name                 => 'mydns.hostname',
          :rgw_swift_url                => 'https://mydns.hostname:443',
          :rgw_swift_url_prefix         => '/',
          :rgw_swift_account_in_url     => true,
          :rgw_swift_versioning_enabled => true,
          :rgw_trust_forwarded_https    => true,
        }
      end

      it { should contain_package('pkgradosgw').with('ensure' => 'installed') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_enable_apis').with_value('s3,swift') }
      it { should contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }
      it { should contain_ceph_config('client.radosgw.custom/host').with_value('foo') }
      it { should contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { should contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_dns_name').with_value('mydns.hostname') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_swift_url').with_value('https://mydns.hostname:443') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_swift_url_prefix').with_value('/') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_swift_account_in_url').with_value(true) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_swift_versioning_enabled').with_value(true) }
      it { should contain_ceph_config('client.radosgw.custom/rgw_trust_forwarded_https').with_value(true) }

      it { should contain_file('/var/lib/ceph/radosgw/ceph-radosgw.custom').with(
        :ensure                  => 'directory',
        :owner                   => 'root',
        :group                   => 'root',
        :mode                    => '0750',
        :selinux_ignore_defaults => true,
      )}

      it { should_not contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway/done') }
      it { should contain_service('radosgw-radosgw.custom').with('ensure' => 'stopped' ) }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      let(:platform_params) do
        case facts[:os]['family']
        when 'Debian'
          {
            :pkg_radosgw => 'radosgw',
            :user        => 'www-data'
          }
        when 'RedHat'
          {
            :pkg_radosgw => 'ceph-radosgw',
            :user        => 'apache'
          }
        end
      end

      it_behaves_like 'ceph::rgw'
    end
  end
end
