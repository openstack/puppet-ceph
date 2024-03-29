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
# Author: Oleksiy Molchanov <omolchanov@mirantis.com>
#
require 'spec_helper'

describe 'ceph::rgw::apache_proxy_fcgi' do
  shared_examples 'ceph::rgw::apache_proxy_fcgi' do
    context 'activated with default params' do
      let :title do
        'radosgw.gateway'
      end

      it { should contain_apache__vhost('foo.example.com-radosgw').with(
        :servername        => 'foo.example.com',
        :serveradmin       => 'root@localhost',
        :port              => 80,
        :docroot           => '/var/www',
        :access_log        => true,
        :error_log         => true,
        :rewrite_rule      => '.* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        :setenv            => 'proxy-nokeepalive 1',
        :proxy_pass        => {'path' => '/', 'url' => 'fcgi://127.0.0.1:9000/'},
      )}

      it { should contain_class('apache').with(
        :default_mods    => false,
        :default_vhost   => false,
        :purge_configs   => true,
        :purge_vhost_dir => true,
      )}

      it { should contain_class('apache::mod::alias') }
      it { should contain_class('apache::mod::auth_basic') }
      it { should contain_class('apache::mod::env') }
      it { should contain_class('apache::mod::proxy') }
      it { should contain_class('apache::mod::proxy_fcgi') }
      it { should contain_class('apache::mod::mime') }
      it { should contain_class('apache::mod::rewrite') }
    end

    context 'activated with custom params' do
      let :title do
        'myid'
      end

      let :params do
        {
          :rgw_dns_name         => 'mydns.hostname',
          :rgw_port             => 1111,
          :admin_email          => 'admin@hostname',
          :syslog               => false,
          :proxy_pass           => {'path' => '/', 'url' => 'fcgi://127.0.0.1:9999/'},
          :apache_mods          => true,
          :apache_vhost         => true,
          :apache_purge_configs => false,
          :apache_purge_vhost   => false,
          :custom_apache_ports  => '8888',
        }
      end

      it { should contain_class('apache').with(
        :default_mods    => true,
        :default_vhost   => true,
        :purge_configs   => false,
        :purge_vhost_dir => false,
      )}

      it { should contain_apache__listen('8888') }

      it { should contain_apache__vhost('mydns.hostname-radosgw').with(
        :servername        => 'mydns.hostname',
        :serveradmin       => 'admin@hostname',
        :port              => 1111,
        :docroot           => '/var/www',
        :access_log        => false,
        :error_log         => false,
        :rewrite_rule      => '.* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
        :setenv            => 'proxy-nokeepalive 1',
        :proxy_pass        => {'path' => '/', 'url' => 'fcgi://127.0.0.1:9999/'},
      )}

      it { should contain_class('apache::mod::alias') }
      it { should contain_class('apache::mod::proxy') }
      it { should contain_class('apache::mod::proxy_fcgi') }
      it { should contain_class('apache::mod::mime') }
      it { should contain_class('apache::mod::rewrite') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::rgw::apache_proxy_fcgi'
    end
  end
end
