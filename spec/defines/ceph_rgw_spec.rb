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

  shared_examples_for 'ceph rgw' do

    describe "activated with default params" do

      let :title do
        'radosgw.gateway'
      end

      it { should contain_package("#{default_params[:pkg_radosgw]}").with('ensure' => 'installed') }
      it { should contain_ceph_config('client.radosgw.gateway/user').with_value("#{default_params[:user]}") }
      it { should contain_ceph_config('client.radosgw.gateway/host').with_value('myhost') }
      it { should contain_ceph_config('client.radosgw.gateway/keyring').with_value('/etc/ceph/ceph.client.radosgw.gateway.keyring') }
      it { should contain_ceph_config('client.radosgw.gateway/log_file').with_value('/var/log/ceph/radosgw.log') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_dns_name').with_value('myhost.domain') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_print_continue').with_value(true) }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_socket_path').with_value('/tmp/radosgw.sock') }
      it { should contain_ceph_config('client.radosgw.gateway/rgw_port').with_value(80) }

      it { should contain_file('/var/lib/ceph/radosgw').with({
        'ensure' => 'directory',
        'mode'   => '0755',
      })}

      it { should contain_file('/var/lib/ceph/radosgw/ceph-radosgw.gateway').with({
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0750',
      })}

      it { should contain_service('radosgw-radosgw.gateway') }

    end

    describe "activated with custom params" do

      let :title do
        'myid'
      end

      let :params do
        {
          :pkg_radosgw        => 'pkgradosgw',
          :rgw_data           => "/var/lib/ceph/radosgw/ceph-myid",
          :user               => 'wwwuser',
          :keyring_path       => "/etc/ceph/ceph.myid.keyring",
          :log_file           => '/var/log/ceph/mylogfile.log',
          :rgw_dns_name       => 'mydns.hostname',
          :rgw_socket_path    => '/some/location/radosgw.sock',
          :rgw_print_continue => false,
          :rgw_port           => 1111,
          :syslog             => false,
        }
      end

      it { should contain_package('pkgradosgw').with('ensure' => 'installed') }

      it { should contain_ceph_config('client.myid/host').with_value('myhost') }
      it { should contain_ceph_config('client.myid/keyring').with_value('/etc/ceph/ceph.myid.keyring') }
      it { should contain_ceph_config('client.myid/log_file').with_value('/var/log/ceph/mylogfile.log') }
      it { should contain_ceph_config('client.myid/rgw_dns_name').with_value('mydns.hostname') }
      it { should contain_ceph_config('client.myid/rgw_print_continue').with_value(false) }
      it { should contain_ceph_config('client.myid/rgw_socket_path').with_value('/some/location/radosgw.sock') }
      it { should contain_ceph_config('client.myid/rgw_port').with_value(1111) }
      it { should contain_ceph_config('client.myid/user').with_value('wwwuser') }

      it { should contain_file('/var/lib/ceph/radosgw/ceph-myid').with( {
        'ensure' => 'directory',
        'owner'  => 'root',
        'group'  => 'root',
        'mode'   => '0750',
      } ) }

      it { should contain_service('radosgw-myid') }

    end

  end

  describe 'Debian Family' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
      }
    end

    let :default_params do
      {
        :pkg_radosgw => 'radosgw',
        :user        => 'www-data',
      }
    end

    it_configures 'ceph rgw'
  end

  describe 'RedHat Family' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :osfamily               => 'RedHat',
        :operatingsystem        => 'RedHat',
        :operatingsystemrelease => '6',
      }
    end

    let :default_params do
      {
        :pkg_radosgw => 'ceph-radosgw',
        :user        => 'apache',
      }
    end

    it_configures 'ceph rgw'
  end

end
