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

  describe 'Debian Family' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :lsbdistid              => 'Ubuntu',
        :lsbdistcodename        => 'trusty',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistrelease         => '14.04',
      }
    end

    describe "create with default params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': fastcgi => true, }
          include ceph
          ceph::rgw { 'radosgw.gateway': }
          ceph::rgw::apache_fastcgi { 'radosgw.gateway': }
        "
      end

      let :title do
        'radosgw.gateway'
      end

      let :params do
        {
          :rgw_keystone_url         => 'http://keystone.default:5000',
          :rgw_keystone_admin_token => 'defaulttoken',
        }
      end

      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_url').with_value('http://keystone.default:5000') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_token').with_value('defaulttoken') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_accepted_roles').with_value('_member_, Member') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_token_cache_size').with_value(500) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_s3_auth_use_keystone').with_value(true) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_revocation_interval').with_value(600) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/nss_db_path').with_value('/var/lib/ceph/nss') }

      it { is_expected.to contain_exec('radosgw.gateway-nssdb-ca').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.default:5000/v2.0/certificates/ca -O - |
  openssl x509 -pubkey | certutil -A -d /var/lib/ceph/nss -n ca -t \"TCu,Cu,Tuw\"
",
         'user'    => 'www-data',
      ) }
      it { is_expected.to contain_exec('radosgw.gateway-nssdb-signing').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.default:5000/v2.0/certificates/signing -O - |
  openssl x509 -pubkey | certutil -A -d /var/lib/ceph/nss -n signing_cert -t \"P,P,P\"
",
         'user'    => 'www-data',
      ) }

    end

    describe "create with custom params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': fastcgi => true, }
          ceph::rgw { 'radosgw.custom': }
          ceph::rgw::apache_fastcgi { 'radosgw.custom': }
        "
      end

      let :title do
        'radosgw.custom'
      end

      let :params do
        {
          :rgw_keystone_url                 => 'http://keystone.custom:5000',
          :rgw_keystone_admin_token         => 'mytoken',
          :rgw_keystone_accepted_roles      => '_role1_,role2',
          :rgw_keystone_token_cache_size    => 100,
          :rgw_s3_auth_use_keystone         => false,
          :use_pki                          => false,
          :rgw_keystone_revocation_interval => 200,
          :nss_db_path                      => '/some/path/to/nss',
        }
      end

      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_url').with_value('http://keystone.custom:5000') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_token').with_value('mytoken') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_accepted_roles').with_value('_role1_,role2') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_token_cache_size').with_value(100) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_s3_auth_use_keystone').with_value(false) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_revocation_interval').with_ensure('absent') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/nss_db_path').with_ensure('absent') }

      it { is_expected.to_not contain_exec('radosgw.custom-nssdb-ca').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.custom:5000/v2.0/certificates/ca -O - |
  openssl x509 -pubkey | certutil -A -d /some/path/to/nss -n ca -t \"TCu,Cu,Tuw\"
",
         'user'    => 'www-data',
      ) }
      it { is_expected.to_not contain_exec('radosgw.custom-nssdb-signing').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.custom:5000/v2.0/certificates/signing -O - |
  openssl x509 -pubkey | certutil -A -d /some/path/to/nss -n signing_cert -t \"P,P,P\"
",
         'user'    => 'www-data',
      ) }

    end

    describe "create with keystone v3 and no pki params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': fastcgi => true, }
          include ceph
          ceph::rgw { 'radosgw.gateway': }
          ceph::rgw::apache_fastcgi { 'radosgw.gateway': }
        "
      end

      let :title do
        'radosgw.gateway'
      end

      let :params do
        {
          :rgw_keystone_url            => 'http://keystone.default:5000',
          :rgw_keystone_version        => 'v3',
          :rgw_keystone_admin_domain   => 'default',
          :rgw_keystone_admin_project  => 'openstack',
          :rgw_keystone_admin_user     => 'rgwuser',
          :rgw_keystone_admin_password => '123456',
        }
      end

      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_url').with_value('http://keystone.default:5000') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_domain').with_value('default') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_project').with_value('openstack') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_user').with_value('rgwuser') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_password').with_value('123456') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_token').with_ensure('absent') }

    end

  end

  describe 'RedHat Family' do

    let :facts do
      {
        :concat_basedir            => '/var/lib/puppet/concat',
        :fqdn                      => 'myhost.domain',
        :hostname                  => 'myhost',
        :lsbdistcodename           => 'Maipo',
        :osfamily                  => 'RedHat',
        :operatingsystem           => 'RedHat',
        :operatingsystemrelease    => '7.2',
        :operatingsystemmajrelease => '7',
      }
    end

    describe "create with default params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': fastcgi => true, }
          include ceph
          ceph::rgw { 'radosgw.gateway': }
          ceph::rgw::apache_fastcgi { 'radosgw.gateway': }
        "
      end

      let :title do
        'radosgw.gateway'
      end

      let :params do
        {
          :rgw_keystone_url         => 'http://keystone.default:5000',
          :rgw_keystone_admin_token => 'defaulttoken',
        }
      end

      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_url').with_value('http://keystone.default:5000') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_token').with_value('defaulttoken') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_accepted_roles').with_value('_member_, Member') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_token_cache_size').with_value(500) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_s3_auth_use_keystone').with_value(true) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_revocation_interval').with_value(600) }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/nss_db_path').with_value('/var/lib/ceph/nss') }

      it { is_expected.to contain_exec('radosgw.gateway-nssdb-ca').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.default:5000/v2.0/certificates/ca -O - |
  openssl x509 -pubkey | certutil -A -d /var/lib/ceph/nss -n ca -t \"TCu,Cu,Tuw\"
",
         'user'    => 'apache',
      ) }
      it { is_expected.to contain_exec('radosgw.gateway-nssdb-signing').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.default:5000/v2.0/certificates/signing -O - |
  openssl x509 -pubkey | certutil -A -d /var/lib/ceph/nss -n signing_cert -t \"P,P,P\"
",
         'user'    => 'apache',
      ) }

    end

    describe "create with custom params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': fastcgi => true, }
          ceph::rgw { 'radosgw.custom': }
          ceph::rgw::apache_fastcgi { 'radosgw.custom': }
        "
      end

      let :title do
        'radosgw.custom'
      end

      let :params do
        {
          :rgw_keystone_url                 => 'http://keystone.custom:5000',
          :rgw_keystone_admin_token         => 'mytoken',
          :rgw_keystone_accepted_roles      => '_role1_,role2',
          :rgw_keystone_token_cache_size    => 100,
          :rgw_s3_auth_use_keystone         => false,
          :use_pki                          => false,
          :rgw_keystone_revocation_interval => 200,
          :nss_db_path                      => '/some/path/to/nss',
        }
      end

      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_url').with_value('http://keystone.custom:5000') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_admin_token').with_value('mytoken') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_accepted_roles').with_value('_role1_,role2') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_token_cache_size').with_value(100) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_s3_auth_use_keystone').with_value(false) }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/rgw_keystone_revocation_interval').with_ensure('absent') }
      it { is_expected.to contain_ceph_config('client.radosgw.custom/nss_db_path').with_ensure('absent') }

      it { is_expected.to_not contain_exec('radosgw.custom-nssdb-ca').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.custom:5000/v2.0/certificates/ca -O - |
  openssl x509 -pubkey | certutil -A -d /some/path/to/nss -n ca -t \"TCu,Cu,Tuw\"
",
         'user'    => 'apache',
      ) }
      it { is_expected.to_not contain_exec('radosgw.custom-nssdb-signing').with(
         'command' => "/bin/true  # comment to satisfy puppet syntax requirements
set -ex
wget --no-check-certificate http://keystone.custom:5000/v2.0/certificates/signing -O - |
  openssl x509 -pubkey | certutil -A -d /some/path/to/nss -n signing_cert -t \"P,P,P\"
",
         'user'    => 'apache',
      ) }

    end

    describe "create with keystone v3 and no pki params" do

      let :pre_condition do
        "
          include ceph::params
          class { 'ceph': fsid => 'd5252e7d-75bc-4083-85ed-fe51fa83f62b' }
          class { 'ceph::repo': fastcgi => true, }
          include ceph
          ceph::rgw { 'radosgw.gateway': }
          ceph::rgw::apache_fastcgi { 'radosgw.gateway': }
        "
      end

      let :title do
        'radosgw.gateway'
      end

      let :params do
        {
          :rgw_keystone_url            => 'http://keystone.default:5000',
          :rgw_keystone_version        => 'v3',
          :rgw_keystone_admin_domain   => 'default',
          :rgw_keystone_admin_project  => 'openstack',
          :rgw_keystone_admin_user     => 'rgwuser',
          :rgw_keystone_admin_password => '123456',
        }
      end

      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_url').with_value('http://keystone.default:5000') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_domain').with_value('default') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_project').with_value('openstack') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_user').with_value('rgwuser') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_password').with_value('123456') }
      it { is_expected.to contain_ceph_config('client.radosgw.gateway/rgw_keystone_admin_token').with_ensure('absent') }

    end


  end
end
