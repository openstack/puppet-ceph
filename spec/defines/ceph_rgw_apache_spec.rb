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

describe 'ceph::rgw::apache' do

  let :pre_condition do
    "include ceph::params
     class { 'ceph::repo':
       extras  => true,
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
        :operatingsystemrelease => '12.04',
        :lsbdistcodename        => 'precise',
        :pkg_fastcgi            => 'libapache2-mod-fastcgi',
      }
    end

    describe 'activated with default params' do

      let :title do
        'radosgw.gateway'
      end

      it { should contain_apache__vhost('myhost.domain-radosgw').with( {
        'servername'        => 'myhost.domain',
        'serveradmin'       => 'root@localhost',
        'port'              => 80,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log_syslog' => true,
        'error_log_syslog'  => true,
        'custom_fragment'   => "
  FastCgiExternalServer /var/www/s3gw.fcgi -socket /tmp/radosgw.sock
  AllowEncodedSlashes On
  ServerSignature Off",
      })}

      it { should contain_class('apache') }
      it { should contain_class('apache::mod::alias') }
      it { should contain_class('apache::mod::auth_basic') }
      it { should contain_apache__mod('fastcgi').with ( { 'package' => 'libapache2-mod-fastcgi' } ) }
      it { should contain_class('apache::mod::mime') }
      it { should contain_class('apache::mod::rewrite') }

      it { should contain_file('/var/www/s3gw.fcgi').with({
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
          :rgw_dns_name    => 'mydns.hostname',
          :rgw_socket_path => '/some/location/radosgw.sock',
          :rgw_port        => 1111,
          :admin_email     => 'admin@hostname',
          :fcgi_file       => '/some/fcgi/filepath',
          :syslog          => false,
        }
      end

      it { should contain_apache__vhost('mydns.hostname-radosgw').with( {
        'servername'        => 'mydns.hostname',
        'serveradmin'       => 'admin@hostname',
        'port'              => 1111,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log_syslog' => false,
        'error_log_syslog'  => false,
        'custom_fragment'   => "
  FastCgiExternalServer /some/fcgi/filepath -socket /some/location/radosgw.sock
  AllowEncodedSlashes On
  ServerSignature Off",
      } ) }

      it { should contain_class('apache') }
      it { should contain_class('apache::mod::alias') }
      it { should contain_class('apache::mod::auth_basic') }
      it { should contain_apache__mod('fastcgi').with ( { 'package' => 'libapache2-mod-fastcgi' } ) }
      it { should contain_class('apache::mod::mime') }
      it { should contain_class('apache::mod::rewrite') }

      it { should contain_file('/some/fcgi/filepath') }

    end
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
        :pkg_fastcgi            => 'libapache2-mod-fastcgi',
      }
    end

    describe 'activated with default params' do

      let :title do
        'radosgw.gateway'
      end

      it { should contain_apache__vhost('myhost.domain-radosgw').with( {
        'servername'        => 'myhost.domain',
        'serveradmin'       => 'root@localhost',
        'port'              => 80,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log_syslog' => true,
        'error_log_syslog'  => true,
        'custom_fragment'   => "
  FastCgiExternalServer /var/www/s3gw.fcgi -socket /tmp/radosgw.sock
  AllowEncodedSlashes On
  ServerSignature Off",
      })}

      it { should contain_class('apache') }
      it { should contain_class('apache::mod::alias') }
      it { should contain_class('apache::mod::auth_basic') }
      it { should contain_apache__mod('fastcgi').with ( { 'package' => 'mod_fastcgi' } ) }
      it { should contain_class('apache::mod::mime') }
      it { should contain_class('apache::mod::rewrite') }

      it { should contain_file('/var/www/s3gw.fcgi').with({
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
          :rgw_dns_name    => 'mydns.hostname',
          :rgw_socket_path => '/some/location/radosgw.sock',
          :rgw_port        => 1111,
          :admin_email     => 'admin@hostname',
          :fcgi_file       => '/some/fcgi/filepath',
          :syslog          => false,
        }
      end

      it { should contain_apache__vhost('mydns.hostname-radosgw').with( {
        'servername'        => 'mydns.hostname',
        'serveradmin'       => 'admin@hostname',
        'port'              => 1111,
        'docroot'           => '/var/www',
        'rewrite_rule'      => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        'access_log_syslog' => false,
        'error_log_syslog'  => false,
        'custom_fragment'   => "
  FastCgiExternalServer /some/fcgi/filepath -socket /some/location/radosgw.sock
  AllowEncodedSlashes On
  ServerSignature Off",
      } ) }

      it { should contain_class('apache') }
      it { should contain_class('apache::mod::alias') }
      it { should contain_class('apache::mod::auth_basic') }
      it { should contain_apache__mod('fastcgi').with ( { 'package' => 'mod_fastcgi' } ) }
      it { should contain_class('apache::mod::mime') }
      it { should contain_class('apache::mod::rewrite') }

      it { should contain_file('/some/fcgi/filepath') }

    end
  end

end
