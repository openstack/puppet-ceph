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

describe 'ceph::rgw::apache' do

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

          Ceph::Pool {
            size => 1,
          }
          ceph::pool { 'data': }
          ceph::pool { 'metadata': }
          ceph::pool { 'rbd': }

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

          ceph::rgw::apache { 'radosgw.gateway':
            rgw_port        => 80,
            rgw_socket_path => '/var/run/ceph/ceph-client.radosgw.gateway.asok',
          }

	  # we declare the rgw pool here even if they're created by the
	  # daemon to make sure we get a replica of 1
          ceph::pool { '.rgw': }
          ceph::pool { '.rgw.control': }
          ceph::pool { '.rgw.gc': }
          ceph::pool { '.rgw.root': }
          ceph::pool { '.users': }
          ceph::pool { '.users.uid': }
          ceph::pool { '.users.swift': }

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

        shell 'radosgw-admin user rm --uid=puppet --purge-data --purge-keys --purge-objects || true' do |r|
          r.exit_code.should be_zero
        end

        shell 'radosgw-admin user create --uid=puppet --display-name=puppet-user' do |r|
          r.exit_code.should be_zero
        end

        shell 'radosgw-admin subuser create --uid=puppet --subuser=puppet:swift --access=full' do |r|
          r.exit_code.should be_zero
        end

        shell 'radosgw-admin key create --subuser=puppet:swift --key-type=swift' do |r|
          r.exit_code.should be_zero
        end

        shell 'radosgw-admin subuser create --uid=puppet --subuser=puppet:swift --access=full' do |r|
          r.exit_code.should be_zero
        end

        shell "radosgw-admin key create --subuser=puppet:swift --key-type=swift --secret='123456'" do |r|
          r.exit_code.should be_zero
        end

        shell "swift -V 1.0 -A http://#{facter.facts['fqdn']}/auth -U puppet:swift -K 123456 stat" do |r|
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
#   RELEASES=dumpling \
#   RS_DESTROY=no \
#   RS_SET=one-ubuntu-server-12042-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system \
#          SPEC=spec/system/ceph_rgw_apache_spec.rb \
#          SPEC_OPTS='--tag cephx' &&
#   git checkout Gemfile
# "
# End:
