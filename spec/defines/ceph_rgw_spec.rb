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

  shared_examples 'ceph::rgw on Ubuntu 14.04' do
    before do
      facts.merge!( :operatingsystem        => 'Ubuntu',
                    :operatingsystemrelease => '14.04',
                    :service_provider       => 'upstart' )
    end

    context 'activated with default params' do
      let :title do
        'radosgw.gateway'
      end

      it { should contain_package('radosgw').with('ensure' => 'installed') }
      it { should contain_ceph_config('client.radosgw.gateway/user').with_value('www-data') }
      it { should contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { should contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_dns_name').with_value('myhost.domain') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_swift_url').with_value('http://myhost.domain:7480') }

      it { should contain_file('/var/lib/ceph/radosgw').with(
        :ensure                  => 'directory',
        :mode                    => '0755',
        :selinux_ignore_defaults => true,
      )}

      it { should contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway').with(
        :ensure                  => 'directory',
        :owner                   => 'root',
        :group                   => 'root',
        :mode                    => '0750',
        :selinux_ignore_defaults => true,
      )}

      it { should contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway/done') }
      it { should contain_service('radosgw-radosgw.gateway') }
    end

    context 'activated with custom params' do
      let :title do
        'radosgw.custom'
      end

      let :params do
        {
          :pkg_radosgw   => 'pkgradosgw',
          :rgw_ensure    => 'stopped',
          :rgw_enable    => false,
          :rgw_data      => "/var/lib/ceph/radosgw/ceph-radosgw.custom",
          :user          => 'wwwuser',
          :keyring_path  => "/etc/ceph/ceph.radosgw.custom.keyring",
          :log_file      => '/var/log/ceph/mylogfile.log',
          :rgw_dns_name  => 'mydns.hostname',
          :rgw_swift_url => 'https://mydns.hostname:443'
        }
      end

      it { should contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { should contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { should contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { should contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_dns_name').with_value('mydns.hostname') }
      it { should contain_ceph_config('client.radosgw.custom/rgw_swift_url').with_value('https://mydns.hostname:443') }

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

  shared_examples 'ceph::rgw on Ubuntu 16.04' do
    before do
      facts.merge!( :operatingsystem        => 'Ubuntu',
                    :operatingsystemrelease => '16.04',
                    :service_provider       => 'systemd' )
    end

    context 'activated with default params' do
      let :title do
        'radosgw.gateway'
      end

      it { should contain_package('radosgw').with('ensure' => 'installed') }
      it { should contain_ceph_config('client.radosgw.gateway/user').with_value('www-data') }
      it { should contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { should contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }

      it { should contain_file('/var/lib/ceph/radosgw').with(
        :ensure                  => 'directory',
        :mode                    => '0755',
        :selinux_ignore_defaults => true,
      )}

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
          :pkg_radosgw  => 'pkgradosgw',
          :rgw_ensure   => 'stopped',
          :rgw_enable   => false,
          :rgw_data     => '/var/lib/ceph/radosgw/ceph-radosgw.custom',
          :user         => 'wwwuser',
          :keyring_path => '/etc/ceph/ceph.radosgw.custom.keyring',
          :log_file     => '/var/log/ceph/mylogfile.log',
        }
      end

      it { should contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { should contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { should contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { should contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }

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

  shared_examples 'ceph::rgw on RedHat' do
    before do
      facts.merge!( :operatingsystem           => 'RedHat',
                    :operatingsystemrelease    => '7.2',
                    :operatingsystemmajrelease => '7' )
    end

    context 'activated with default params' do
      let :title do
        'radosgw.gateway'
      end

      it { should contain_package('ceph-radosgw').with('ensure' => 'installed') }
      it { should contain_ceph_config('client.radosgw.gateway/user').with_value('apache') }
      it { should contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { should contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }

      it { should contain_file('/var/lib/ceph/radosgw').with(
        :ensure                  => 'directory',
        :mode                    => '0755',
        :selinux_ignore_defaults => true,
      )}

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
          :pkg_radosgw        => 'pkgradosgw',
          :rgw_ensure         => 'stopped',
          :rgw_enable         => false,
          :rgw_data           => "/var/lib/ceph/radosgw/ceph-radosgw.custom",
          :user               => 'wwwuser',
          :keyring_path       => "/etc/ceph/ceph.radosgw.custom.keyring",
          :log_file           => '/var/log/ceph/mylogfile.log',
        }
      end

      it { should contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { should contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { should contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { should contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }

      it { should contain_file('/var/lib/ceph/radosgw/ceph-radosgw.custom').with(
        :ensure                  => 'directory',
        :owner                   => 'root',
        :group                   => 'root',
        :mode                    => '0750',
        :selinux_ignore_defaults => true,
      )}

      it { should contain_service('radosgw-radosgw.custom').with('ensure' => 'stopped' ) }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts( :concat_basedir => '/var/lib/puppet/concat',
                                           :fqdn           => 'myhost.domain',
                                           :hostname       => 'myhost' ))
      end

      if facts[:operatingsystem] == 'Ubuntu'
        it_behaves_like 'ceph::rgw on Ubuntu 14.04'
        it_behaves_like 'ceph::rgw on Ubuntu 16.04'
      end

      if facts[:osfamily] == 'RedHat'
        it_behaves_like 'ceph::rgw on RedHat'
      end
    end
  end
end
