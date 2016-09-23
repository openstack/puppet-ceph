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
# Author: David Gurtner <aldavud@crimson.ch>
#
require 'spec_helper'

describe 'ceph::rgw::apache_fastcgi' do

  let :pre_condition do
    "include ceph::params
     class { 'ceph::repo':
       fastcgi => true,
     }"
  end

  describe 'Debian Family' do

    let :facts do
      {
        :concat_basedir         => '/var/lib/puppet/concat',
        :fqdn                   => 'myhost.domain',
        :hostname               => 'myhost',
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :lsbdistid              => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :lsbdistrelease         => '14.04',
        :lsbdistcodename        => 'trusty',
        :pkg_fastcgi            => 'libapache2-mod-fastcgi',
      }
    end

    describe 'activated with default params' do

      let :title do
        'radosgw.gateway'
      end

      it { is_expected.to contain_apache__vhost('myhost.domain-radosgw').with( {
        'servername'        => 'myhost.domain',
        'serveradmin'       => 'root@localhost',
        'port'              => 80,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log'        => true,
        'error_log'         => true,
        'fastcgi_server'    => '/var/www/s3gw.fcgi',
        'fastcgi_socket'    => '/tmp/radosgw.sock',
        'fastcgi_dir'       => '/var/www',
      })}

      it { is_expected.to contain_class('apache').with(
        'default_mods'    => false,
        'default_vhost'   => false,
        'purge_configs'   => true,
        'purge_vhost_dir' => true,
      )}
      it { is_expected.to contain_class('apache::mod::alias') }
      it { is_expected.to contain_class('apache::mod::auth_basic') }
      it { is_expected.to contain_class('apache::mod::fastcgi') }
      it { is_expected.to contain_class('apache::mod::mime') }
      it { is_expected.to contain_class('apache::mod::rewrite') }

      it { is_expected.to contain_file('/var/www/s3gw.fcgi').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0750',
        'content' => "#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n radosgw.gateway",
      })}

    end

    describe "activated with custom params" do

      let :title do
        'myid'
      end

      let :params do
        {
          :rgw_dns_name         => 'mydns.hostname',
          :rgw_socket_path      => '/some/location/radosgw.sock',
          :rgw_port             => 1111,
          :admin_email          => 'admin@hostname',
          :fcgi_file            => '/some/fcgi/filepath',
          :syslog               => false,
          :apache_mods          => true,
          :apache_vhost         => true,
          :apache_purge_configs => false,
          :apache_purge_vhost   => false,
          :custom_apache_ports  => '8888',
        }
      end

      it { is_expected.to contain_apache__vhost('mydns.hostname-radosgw').with( {
        'servername'        => 'mydns.hostname',
        'serveradmin'       => 'admin@hostname',
        'port'              => 1111,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log'        => false,
        'error_log'         => false,
        'fastcgi_server'    => '/some/fcgi/filepath',
        'fastcgi_socket'    => '/some/location/radosgw.sock',
        'fastcgi_dir'       => '/var/www',
      } ) }

      it { is_expected.to contain_class('apache').with(
        'default_mods'    => true,
        'default_vhost'   => true,
        'purge_configs'   => false,
        'purge_vhost_dir' => false,
      )}
      it { is_expected.to contain_apache__listen('8888') }
      it { is_expected.to contain_class('apache::mod::alias') }
      it { is_expected.to contain_class('apache::mod::fastcgi') }
      it { is_expected.to contain_class('apache::mod::mime') }
      it { is_expected.to contain_class('apache::mod::rewrite') }

      it { is_expected.to contain_file('/some/fcgi/filepath') }

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
        :pkg_fastcgi               => 'libapache2-mod-fastcgi',
      }
    end

    describe 'activated with default params' do

      let :title do
        'radosgw.gateway'
      end

      it { is_expected.to contain_apache__vhost('myhost.domain-radosgw').with( {
        'servername'        => 'myhost.domain',
        'serveradmin'       => 'root@localhost',
        'port'              => 80,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log'        => true,
        'error_log'         => true,
        'fastcgi_server'    => '/var/www/s3gw.fcgi',
        'fastcgi_socket'    => '/tmp/radosgw.sock',
        'fastcgi_dir'       => '/var/www',
      })}

      it { is_expected.to contain_class('apache').with(
        'default_mods'    => false,
        'default_vhost'   => false,
        'purge_configs'   => true,
        'purge_vhost_dir' => true,
      )}
      it { is_expected.to contain_class('apache::mod::alias') }
      it { is_expected.to contain_class('apache::mod::auth_basic') }
      it { is_expected.to contain_class('apache::mod::fastcgi') }
      it { is_expected.to contain_class('apache::mod::mime') }
      it { is_expected.to contain_class('apache::mod::rewrite') }

      it { is_expected.to contain_file('/var/www/s3gw.fcgi').with({
        'ensure'  => 'file',
        'owner'   => 'root',
        'group'   => 'root',
        'mode'    => '0750',
        'content' => "#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n radosgw.gateway",
      })}

    end

    describe "activated with custom params" do

      let :title do
        'myid'
      end

      let :params do
        {
          :rgw_dns_name         => 'mydns.hostname',
          :rgw_socket_path      => '/some/location/radosgw.sock',
          :rgw_port             => 1111,
          :admin_email          => 'admin@hostname',
          :fcgi_file            => '/some/fcgi/filepath',
          :syslog               => false,
          :apache_mods          => true,
          :apache_vhost         => true,
          :apache_purge_configs => false,
          :apache_purge_vhost   => false,
          :custom_apache_ports  => '8888',
        }
      end

      it { is_expected.to contain_class('apache').with(
        'default_mods'    => true,
        'default_vhost'   => true,
        'purge_configs'   => false,
        'purge_vhost_dir' => false,
      )}
      it { is_expected.to contain_apache__listen('8888') }
      it { is_expected.to contain_apache__vhost('mydns.hostname-radosgw').with( {
        'servername'        => 'mydns.hostname',
        'serveradmin'       => 'admin@hostname',
        'port'              => 1111,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log'        => false,
        'error_log'         => false,
        'fastcgi_server'    => '/some/fcgi/filepath',
        'fastcgi_socket'    => '/some/location/radosgw.sock',
        'fastcgi_dir'       => '/var/www',
      } ) }

      it { is_expected.to contain_class('apache::mod::alias') }
      it { is_expected.to contain_class('apache::mod::fastcgi') }
      it { is_expected.to contain_class('apache::mod::mime') }
      it { is_expected.to contain_class('apache::mod::rewrite') }

      it { is_expected.to contain_file('/some/fcgi/filepath') }

    end
  end

end
