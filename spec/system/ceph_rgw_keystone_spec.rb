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
require 'spec_helper_system'

describe 'ceph::rgw::keystone' do

  purge = <<-EOS
   package { [
      'python-ceph',
      'ceph-common',
      'librados2',
      'librbd1',
      'radosgw',
     ]:
     ensure => purged
   }
  EOS

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'emperor', 'firefly' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  radosgw_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRwg=='

  keystone_admin_token = 'keystonetoken'
  keystone_password = '123456'
  keystone_db_password = '123456'

  releases.each do |release|
    describe release, :cephx do
      it 'should install one monitor/osd with a rgw' do
        pp = <<-EOS
          $user = $::osfamily ? {
            'RedHat' => 'apache',
            default => 'www-data',
          }

          $pkg_swift = $osfamily ? {
            'RedHat' => 'openstack-swift',
            default  => 'swift',
          }

          # setup a keystone instance (need havana at least)
          include apt
          apt::source { 'cloudarchive-havana':
            location          => 'http://ubuntu-cloud.archive.canonical.com/ubuntu',
            release           => 'precise-updates/havana',
            repos             => 'main',
            include_src       => false,
            required_packages => 'ubuntu-cloud-keyring',
          }

          class { 'mysql::server': }
          ->
          class { 'keystone::db::mysql':
            password      => '#{keystone_db_password}',
            allowed_hosts => '%',
          }
          ->
          class { 'keystone':
            verbose             => True,
            catalog_type        => 'sql',
            admin_token         => '#{keystone_admin_token}',
            database_connection => "mysql://keystone_admin:#{keystone_db_password}@${::ipaddress}/keystone",
            admin_endpoint      => "http://${::ipaddress}:35357/v2.0",
          }
          ->
          class { 'keystone::roles::admin':
            email        => 'admin@example.com',
            password     => '#{keystone_password}',
          }
          ->
          class { 'keystone::endpoint':
            public_url   => "http://${::ipaddress}:5000/v2.0",
            admin_url    => "http://${::ipaddress}:35357/v2.0",
            internal_url => "http://${::ipaddress}:5000/v2.0",
            region       => 'example-1',
          }

          # default pools size to 1 for local test
          Ceph::Pool {
            size => 1,
          }
          ceph::pool { 'data': }
          ceph::pool { 'metadata': }
          ceph::pool { 'rbd': }
          # we declare the rgw pool here even if they're created by the
          # daemon to make sure we get a replica of 1
          ceph::pool { '.rgw': }
          ceph::pool { '.rgw.control': }
          ceph::pool { '.rgw.gc': }
          ceph::pool { '.rgw.root': }
          ceph::pool { '.users': }
          ceph::pool { '.users.uid': }
          ceph::pool { '.users.swift': }

          ceph_config {
           'global/mon_data_avail_warn': value => 10; # FIXME: workaround for health warn in mon
           'global/osd_journal_size':    value => '100';
          }

          # ceph setup
          class { 'ceph::repo':
            release => '#{release}',
            extras  => true,
            fastcgi => true,
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            key => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
          }
          ->
          ceph::key { 'client.admin':
            secret         => '#{admin_key}',
            cap_mon        => 'allow *',
            cap_osd        => 'allow *',
            cap_mds        => 'allow *',
            inject         => true,
            inject_as_id   => 'mon.',
            inject_keyring => '/var/lib/ceph/mon/ceph-a/keyring',
          }
          ->
          ceph::key { 'client.radosgw.gateway':
            user    => $user,
            secret  => '#{radosgw_key}',
            cap_mon => 'allow rw',
            cap_osd => 'allow rwx',
            inject  => true,
          }
          ->
          exec { 'bootstrap-key':
            command => '/usr/sbin/ceph-create-keys --id a',
          }
          ->
          ceph::osd { '/srv/data': }

          # setup ceph radosgw
          host { $::fqdn: # workaround for bad 'hostname -f' in vagrant box
            ip => $ipaddress,
          }
          ->
          file { '/var/run/ceph': # workaround for bad sysvinit script (ignores socket)
            ensure => directory,
            owner  => $user,
          }
          ->
          ceph::rgw { 'radosgw.gateway':
            rgw_port        => 80,
            rgw_socket_path => '/var/run/ceph/ceph-client.radosgw.gateway.asok',
          }
          ->
          package { $pkg_swift:  # required for tests below
            ensure => present,
          }
          Ceph::Osd['/srv/data'] -> Service['radosgw-radosgw.gateway']

          ceph::rgw::apache { 'radosgw.gateway':
            rgw_port        => 80,
            rgw_socket_path => '/var/run/ceph/ceph-client.radosgw.gateway.asok',
          }

          # add the require keystone endpoints for radosgw (object-store)
          ceph::rgw::keystone { 'radosgw.gateway':
            rgw_keystone_url         => "http://${::ipaddress}:5000/v2.0",
            rgw_keystone_admin_token => '#{keystone_admin_token}',
          }
          Service['keystone'] -> Ceph::Rgw::Keystone['radosgw.gateway']

          keystone_service { 'swift':
            ensure => present,
            type => 'object-store',
            description => 'Openstack Object Storage Service',
          }
          keystone_endpoint { 'example-1/swift':
            ensure => present,
            public_url => "http://${::ipaddress}:80/swift/v1",
            admin_url => "http://${::ipaddress}:80/swift/v1",
            internal_url => "http://${::ipaddress}:80/swift/v1",
          }
          Keystone_service<||> -> Ceph::Rgw::Keystone['radosgw.gateway']
          Keystone_endpoint<||> -> Ceph::Rgw::Keystone['radosgw.gateway']

          # add a testuser for validation below
          keystone_user { 'testuser':
            ensure   => present,
            enabled  => True,
            email    => 'testuser@example',
            password => '123456',
            tenant   => 'openstack',
          }
          Keystone_user<||> -> Ceph::Rgw::Keystone['radosgw.gateway']

          keystone_user_role { 'testuser@openstack':
            ensure => present,
            roles  => ['_member_'],
          }
          Keystone_user_role<||> -> Ceph::Rgw::Keystone['radosgw.gateway']

        EOS

        osfamily = facter.facts['osfamily']
        servicequery = {
          'Debian' => 'status radosgw id=radosgw.gateway',
          'RedHat' => 'service ceph-radosgw status id=radosgw.gateway',
        }

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell servicequery[osfamily] do |r|
          r.exit_code.should be_zero
        end

        shell "OS_TENANT_NAME=openstack OS_USERNAME=testuser OS_PASSWORD=123456 OS_AUTH_URL=http://127.0.0.1:5000/v2.0 swift list" do |r|
          r.exit_code.should be_zero
        end

      end

      it 'should purge all packages' do
        puppet_apply(purge) do |r|
          r.exit_code.should_not == 1
        end
      end
    end
  end

end
# Local Variables:
# compile-command: "cd ../..
#   (
#     cd .rspec_system/vagrant_projects/one-ubuntu-server-12042-x64
#     vagrant destroy --force
#   )
#   cp -a Gemfile-rspec-system Gemfile
#   BUNDLE_PATH=/tmp/vendor bundle install --no-deployment
#   MACHINES=first \
#   RELEASES=dumpling \
#   DATAS=/srv/data \
#   RS_DESTROY=no \
#   RS_SET=one-ubuntu-server-12042-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system \
#          SPEC=spec/system/ceph_rgw_keystone_spec.rb \
#          SPEC_OPTS='--tag cephx' &&
#   git checkout Gemfile
# "
# End:
