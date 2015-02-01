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
require 'spec_helper_system'

describe 'ceph::rgw::apache' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'emperor', 'firefly' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  mon_key ='AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  radosgw_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRwg=='
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  releases.each do |release|
    describe release do
      it 'should install one monitor/osd with a rgw' do
        pp = <<-EOS
          $user = $::osfamily ? {
            'RedHat' => 'apache',
            default => 'www-data',
          }

          class { 'ceph::repo':
            release => '#{release}',
            extras  => true,
            fastcgi => true,
          }
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
          }
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            key => '#{mon_key}',
          }
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
          ceph::osd { '/dev/sdb': }

          #host { $::fqdn: # workaround for bad 'hostname -f' in vagrant box
          #  ip => $ipaddress,
          #}
          #->
          file { '/var/run/ceph': # workaround for bad sysvinit script (ignores socket)
            ensure => directory,
            owner  => $user,
          }
          ->
          ceph::rgw { 'radosgw.gateway':
            rgw_port        => 80,
            rgw_socket_path => '/var/run/ceph/ceph-client.radosgw.gateway.asok',
          }

          ceph::rgw::apache { 'radosgw.gateway':
            rgw_port        => 80,
            rgw_socket_path => '/var/run/ceph/ceph-client.radosgw.gateway.asok',
          }

          # we declare all pools here even if they're created by the
          # daemon to make sure we get a replica of 1
          Ceph::Pool {
            size => 1,
          }
          ceph::pool { 'data': }
          ceph::pool { 'metadata': }
          ceph::pool { 'rbd': }
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

#        shell 'radosgw-admin user rm --uid=puppet --purge-data --purge-keys --purge-objects || true' do |r|
#          r.exit_code.should be_zero
#        end

        shell 'radosgw-admin user create --uid=puppet --display-name=puppet-user' do |r|
          r.exit_code.should be_zero
        end

        shell 'radosgw-admin subuser create --uid=puppet --subuser=puppet:swift --access=full' do |r|
          r.exit_code.should be_zero
        end

        # need to create subuser key twice, due to http://tracker.ceph.com/issues/9155
        shell "radosgw-admin key create --subuser=puppet:swift --key-type=swift --secret='123456'" do |r|
          r.exit_code.should be_zero
        end

        shell "radosgw-admin key create --subuser=puppet:swift --key-type=swift --secret='123456'" do |r|
          r.exit_code.should be_zero
        end

        shell 'curl -i -H "X-Auth-User: puppet:swift" -H "X-Auth-Key: 123456" http://first/auth/v1.0/' do |r|
          r.exit_code.should be_zero
        end

#        shell "curl -i -H 'X-Auth-User: puppet:swift' -H 'X-Auth-Key: 123456' http://#{facter.facts['fqdn']}/auth/v1.0/" do |r|
#          r.exit_code.should be_zero
#        end


      end

      it 'should purge everything' do
        pp = <<-EOS
         ceph::osd { '/dev/sdb':
            ensure => absent,
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
        end

        shell 'ceph-disk zap /dev/sdb'

        purge = <<-EOS
          ceph::mon { 'a': ensure => absent }
          ->
          file { [
             '/var/lib/ceph/bootstrap-osd/ceph.keyring',
             '/etc/ceph/ceph.client.admin.keyring',
             '/etc/ceph/ceph.client.radosgw.gateway',
            ]:
            ensure => absent
          }
          ->
          package { #{packages}:
            ensure => purged
          }
          class { 'ceph::repo':
            release => '#{release}',
            extras  => true,
            fastcgi => true,
            ensure  => absent,
          }
          # apache
          #include ceph::params
          #package { $::ceph::params::pkg_fastcgi:
          #  ensure => absent,
          #}
          #->
          class { 'apache':
            service_ensure => stopped,
            service_enable => false,
            #package_ensure => absent,
          }
          apache::vhost { "$fqdn-radosgw":
            ensure  => absent,
            docroot => '/var/www',
          }
        EOS

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
#   MACHINES=first \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_rgw_apache_spec.rb &&
#   git checkout Gemfile
# "
# End:
