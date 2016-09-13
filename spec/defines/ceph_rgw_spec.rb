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

  describe 'Ubuntu 14.04' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :service_provider       => 'upstart',
      }
    end

    describe "activated with default params" do

      let :title do
        'radosgw.gateway'
      end

      it { is_expected.to contain_package('radosgw').with('ensure' => 'installed') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/user').with_value('www-data') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_dns_name').with_value('myhost.domain') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_print_continue').with_value(false) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_socket_path').with_value('/tmp/radosgw.sock') }

      it { is_expected.to contain_file('/var/lib/ceph/radosgw').with({
        'ensure'                  => 'directory',
        'mode'                    => '0755',
        'selinux_ignore_defaults' => true,
      })}

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway').with({
        'ensure'                  => 'directory',
        'owner'                   => 'root',
        'group'                   => 'root',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      })}

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway/done') }

      it { is_expected.to contain_service('radosgw-radosgw.gateway') }

    end

    describe "activated with custom params" do

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
          :rgw_dns_name       => 'mydns.hostname',
          :rgw_socket_path    => '/some/location/radosgw.sock',
          :rgw_print_continue => true,
          :rgw_port           => 1111,
          :syslog             => false,
        }
      end

      it { is_expected.to contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { is_expected.to contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_dns_name').with_value('mydns.hostname') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_print_continue').with_value(true) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_socket_path').with_value('/some/location/radosgw.sock') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_port').with_value(1111) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.custom').with( {
        'ensure'                  => 'directory',
        'owner'                   => 'root',
        'group'                   => 'root',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      } ) }

      it { is_expected.to_not contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway/done') }

      it { is_expected.to contain_service('radosgw-radosgw.custom').with('ensure' => 'stopped' ) }

    end
  end

  describe 'Ubuntu 16.04' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '16.04',
        :service_provider       => 'systemd',
      }
    end

    describe "activated with default params" do

      let :title do
        'radosgw.gateway'
      end

      it { is_expected.to contain_package('radosgw').with('ensure' => 'installed') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/user').with_value('www-data') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_dns_name').with_value('myhost.domain') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_print_continue').with_value(false) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_socket_path').with_value('/tmp/radosgw.sock') }

      it { is_expected.to contain_file('/var/lib/ceph/radosgw').with({
        'ensure'                  => 'directory',
        'mode'                    => '0755',
        'selinux_ignore_defaults' => true,
      })}

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway').with({
        'ensure'                  => 'directory',
        'owner'                   => 'root',
        'group'                   => 'root',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      })}

      it { is_expected.to contain_service('radosgw-radosgw.gateway') }

    end

    describe "activated with custom params" do

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
          :rgw_dns_name       => 'mydns.hostname',
          :rgw_socket_path    => '/some/location/radosgw.sock',
          :rgw_print_continue => true,
          :rgw_port           => 1111,
          :syslog             => false,
        }
      end

      it { is_expected.to contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { is_expected.to contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_dns_name').with_value('mydns.hostname') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_print_continue').with_value(true) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_socket_path').with_value('/some/location/radosgw.sock') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_port').with_value(1111) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.custom').with( {
        'ensure'                  => 'directory',
        'owner'                   => 'root',
        'group'                   => 'root',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      } ) }

      it { is_expected.to_not contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway/done') }

      it { is_expected.to contain_service('radosgw-radosgw.custom').with('ensure' => 'stopped' ) }

    end
  end

  describe 'RedHat Family' do

    let :facts do
      {
        :concat_basedir            => '/var/lib/puppet/concat',
        :fqdn                      => 'myhost.domain',
        :hostname                  => 'myhost',
        :osfamily                  => 'RedHat',
        :operatingsystem           => 'RedHat',
        :operatingsystemrelease    => '7.2',
        :operatingsystemmajrelease => '7',
      }
    end

    describe "activated with default params" do

      let :title do
        'radosgw.gateway'
      end

      it { is_expected.to contain_package('ceph-radosgw').with('ensure' => 'installed') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/user').with_value('apache') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_dns_name').with_value('myhost.domain') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_print_continue').with_value(false) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_socket_path').with_value('/tmp/radosgw.sock') }

      it { is_expected.to contain_file('/var/lib/ceph/radosgw').with({
        'ensure'                  => 'directory',
        'mode'                    => '0755',
        'selinux_ignore_defaults' => true,
      })}

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway').with({
        'ensure'                  => 'directory',
        'owner'                   => 'root',
        'group'                   => 'root',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      })}

      it { is_expected.to contain_service('radosgw-radosgw.gateway') }

    end

    describe "activated with custom params" do

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
          :rgw_dns_name       => 'mydns.hostname',
          :rgw_socket_path    => '/some/location/radosgw.sock',
          :rgw_print_continue => true,
          :rgw_port           => 1111,
          :syslog             => false,
        }
      end

      it { is_expected.to contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { is_expected.to contain_ceph_config('client.radosgw.custom/host').with_value('myhost') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/keyring').with_value('/etc/ceph/ceph.radosgw.custom.keyring') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_dns_name').with_value('mydns.hostname') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_print_continue').with_value(true) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_socket_path').with_value('/some/location/radosgw.sock') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_port').with_value(1111) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/user').with_value('wwwuser') }

      it { is_expected.to contain_file('/var/lib/ceph/radosgw/ceph-radosgw.custom').with( {
        'ensure'                  => 'directory',
        'owner'                   => 'root',
        'group'                   => 'root',
        'mode'                    => '0750',
        'selinux_ignore_defaults' => true,
      } ) }

      it { is_expected.to contain_service('radosgw-radosgw.custom').with('ensure' => 'stopped' ) }

    end
  end

end
