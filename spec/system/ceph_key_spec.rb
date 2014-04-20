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

describe 'ceph::key' do

  purge = <<-EOS
   Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

   ceph::mon { 'a': ensure => absent }
   ->
   file { '/var/lib/ceph/bootstrap-osd/ceph.keyring': ensure => absent }
   ->
   package { [
      'python-ceph',
      'ceph-common',
      'librados2',
      'librbd1',
     ]:
     ensure => purged
   }
  EOS

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'cuttlefish', 'dumpling', 'emperor' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  mon_key = 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
  something_key = 'AQD44lJTqGB4LhAA3zV8mKlO9UKFNLwg2f3lvQ=='

  releases.each do |release|
    describe release do
      it 'should install and not inject client.admin key' do
        pp = <<-EOS
          Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
          
          class { 'ceph::repo':
            release => '#{release}',
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
            authentication_type => 'none',
          }
          ->
          ceph::key { 'client.admin':
            secret  => 'AQA98KdSmOs9JRAArCunQAB8d9eZGRfyadminQ==',
            cap_mon => 'allow *',
            cap_osd => 'allow *',
            cap_mds => 'allow *',
            mode    => 0600,
            user    => 'root',
            group   => 'root',
            inject  => false,
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            authentication_type => 'none',
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ls -l /etc/ceph/ceph.client.admin.keyring' do |r|
          r.stdout.should =~ /.*-rw-------.*root\sroot.*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        shell 'cat /etc/ceph/ceph.client.admin.keyring' do |r|
          r.stdout.should =~ /.*\[client.admin\].*key = AQA98KdSmOs9JRAArCunQAB8d9eZGRfyadminQ==.*caps mds = "allow \*".*caps mon = "allow \*".*caps osd = "allow \*".*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should install and inject client.volumes key' do
        pp = <<-EOS
          Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

          class { 'ceph::repo':
            release => '#{release}',
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
            authentication_type => 'none',
          }
          ->
          ceph::key { 'client.admin':
            secret  => 'AQA98KdSmOs9JRAArCunQAB8d9eZGRfyadminQ==',
            cap_mon => 'allow *',
            cap_osd => 'allow *',
            cap_mds => 'allow *',
            inject  => false,
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            authentication_type => 'none',
          }
          ->
          ceph::key { 'client.volumes':
            secret  => 'AQA98KdSmOs9JRAArCunQAB8d9eZGRvolumesQ==',
            cluster => 'ceph',
            cap_mon => 'allow *',
            cap_osd => 'allow rw',
            mode    => 0600,
            user    => 'nobody',
            group   => 'nogroup',
            inject  => true,
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ceph auth list' do |r|
          r.stdout.should =~ /.*client\.volumes.*key:\sAQA98KdSmOs9JRAArCunQAB8d9eZGRvolumesQ==.*/m
          # r.stderr.should be_empty # ceph auth writes to stderr!
          r.exit_code.should be_zero
        end

        shell 'ls -l /etc/ceph/ceph.client.volumes.keyring' do |r|
          r.stdout.should =~ /.*-rw-------.*nobody\snogroup.*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        shell 'cat /etc/ceph/ceph.client.volumes.keyring' do |r|
          r.stdout.should =~ /.*\[client.volumes\].*key = AQA98KdSmOs9JRAArCunQAB8d9eZGRvolumesQ==.*caps mon = "allow \*".*caps osd = "allow rw".*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall one monitor and all packages' do
        puppet_apply(purge) do |r|
          r.exit_code.should_not == 1
        end
      end
    end
  end

  releases.each do |release|
    describe release do
      it 'should install and inject client.something key' do
        pp = <<-EOS
          Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

          class { 'ceph::repo':
            release => '#{release}',
          }
          ->
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => $::ipaddress_eth0,
          }
          ->
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            key => '#{mon_key}',
          }
          ->
          ceph::key { 'client.something':
            secret         => '#{something_key}',
            cap_mon        => 'allow *',
            cap_osd        => 'allow rw',
            mode           => 0600,
            user           => 'nobody',
            group          => 'nogroup',
            inject         => true,
            inject_as_id   => 'mon.',
            inject_keyring => '/var/lib/ceph/mon/ceph-a/keyring',
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ceph auth list' do |r|
          r.stdout.should =~ /.*client\.something.*key:\s#{something_key}.*/m
          # r.stderr.should be_empty # ceph auth writes to stderr!
          r.exit_code.should be_zero
        end

        shell 'ls -l /etc/ceph/ceph.client.something.keyring' do |r|
          r.stdout.should =~ /.*-rw-------.*nobody\snogroup.*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall one monitor and all packages' do
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
#     cd .rspec_system/vagrant_projects/two-ubuntu-server-12042-x64
#     vagrant destroy --force
#   )
#   cp -a Gemfile-rspec-system Gemfile
#   BUNDLE_PATH=/tmp/vendor bundle install --no-deployment
#   MACHINES=first \
#   RELEASES=cuttlefish \
#   RS_DESTROY=no \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_key_spec.rb
#   git checkout Gemfile
# "
# End:
