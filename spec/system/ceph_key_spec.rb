#
# Copyright (C) 2014 Catalyst IT Limited.
# Copyright (C) 2014 Cloudwatt <libre.licensing@cloudwatt.com>
# Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: Loic Dachary <loic@dachary.org>
# Author: David Gurtner <aldavud@crimson.ch>
#

require 'spec_helper_system'

describe 'ceph::key' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  mon_key = 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg==' # client.admin key needs to contain a / character!
  volume_key = 'AQAMTVRTSOHmHBAAH5d1ukHrAnxuSbrWSv9KGA=='
  mon_host = '$::ipaddress'
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  releases.each do |release|
    purge = <<-EOS
      ceph::mon { 'a': ensure => absent }
      ->
      file { [
         '/var/lib/ceph/bootstrap-osd/ceph.keyring',
         '/etc/ceph/ceph.client.admin.keyring',
         '/etc/ceph/ceph.client.volume',
        ]:
        ensure => absent
      }
      ->
      package { [
         'python-ceph',
         'ceph-common',
         'librados2',
         'librbd1',
         'libcephfs1',
        ]:
        ensure => purged
      }
    EOS

    describe release do
      before(:all) do
        pp = <<-EOS
          class { 'ceph::repo':
            release => '#{release}',
          }
        EOS

        machines.each do |mon|
          puppet_apply(:node => mon, :code => pp) do |r|
            r.exit_code.should_not == 1
          end
        end
      end

      after(:all) do
        pp = <<-EOS
          package { #{packages}:
            ensure => purged
          }
          class { 'ceph::repo':
            release => '#{release}',
            ensure  => absent,
          }
        EOS

        machines.each do |mon|
          puppet_apply(:node => mon, :code => pp) do |r|
            r.exit_code.should_not == 1
          end
        end
      end

      it 'should install and not inject client.admin key' do
        pp = <<-EOS
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => #{mon_host},
            authentication_type => 'none',
          }
          ceph::key { 'client.admin':
            secret  => '#{admin_key}',
            cap_mon => 'allow *',
            cap_osd => 'allow *',
            cap_mds => 'allow *',
            mode    => 0600,
            user    => 'root',
            group   => 'root',
            inject  => false,
          }
          # this is the dependency we want to prove to work here,
          # we do not need to specify dependencies normally.
          ->
          ceph::mon { 'a':
            public_addr => #{mon_host},
            authentication_type => 'none',
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ceph auth list' do |r|
          r.stdout.should_not =~ /client.admin/
          r.exit_code.should be_zero
        end

        shell 'ls -l /etc/ceph/ceph.client.admin.keyring' do |r|
          r.stdout.should =~ /.*-rw-------.*root\sroot.*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        shell 'cat /etc/ceph/ceph.client.admin.keyring' do |r|
          r.stdout.should =~ /.*\[client.admin\].*key = #{admin_key}.*caps mds = "allow \*".*caps mon = "allow \*".*caps osd = "allow \*".*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall one monitor and all packages' do
        puppet_apply(purge) do |r|
          r.exit_code.should_not == 1
        end
      end

      it 'should install and inject client.volumes key' do
        osfamily = facter.facts['osfamily']
        operatingsystem = facter.facts['operatingsystem']

        if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
          nogroup = 'nogroup'
        end
        if osfamily == 'RedHat'
          nogroup = 'nobody'
        end

        pp = <<-EOS
          class { 'ceph':
            fsid => '#{fsid}',
            mon_host => #{mon_host},
          }
          ceph::mon { 'a':
            public_addr => #{mon_host},
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
          # as we are injecting using the client.admin key we
          # need this dependency
          ->
          ceph::key { 'client.volumes':
            secret  => '#{volume_key}',
            cluster => 'ceph',
            cap_mon => 'allow *',
            cap_osd => 'allow rw',
            mode    => 0600,
            user    => 'nobody',
            group   => '#{nogroup}',
            inject  => true,
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
          r.stdout.should_not =~ /Exec\[ceph-key-client\.admin\]/ # client.admin key needs to contain a / character!
        end

        shell 'ceph auth list' do |r|
          r.stdout.should =~ /.*client\.volumes.*key:\s#{volume_key}.*/m
          # r.stderr.should be_empty # ceph auth writes to stderr!
          r.exit_code.should be_zero
        end

        shell 'ls -l /etc/ceph/ceph.client.volumes.keyring' do |r|
          r.stdout.should =~ /.*-rw-------.*nobody\s#{nogroup}.*/m
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        shell 'cat /etc/ceph/ceph.client.volumes.keyring' do |r|
          r.stdout.should =~ /.*\[client.volumes\].*key = #{volume_key}.*caps mon = "allow \*".*caps osd = "allow rw".*/m
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
#     cd .rspec_system/vagrant_projects/ubuntu-server-1204-x64
#     vagrant destroy --force
#   )
#   cp -a Gemfile-rspec-system Gemfile
#   BUNDLE_PATH=/tmp/vendor bundle install --no-deployment
#   MACHINES=first \
#   RELEASES=dumpling \
#   RS_DESTROY=no \
#   RS_SET=ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_key_spec.rb &&
#   git checkout Gemfile
# "
# End:
