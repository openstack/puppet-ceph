#
#  Copyright 2014 Cloudwatt <libre-licensing@cloudwatt.com>
#
#  Author: Loic Dachary <loic@dachary.org>
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
require 'spec_helper_system'

describe 'ceph::osd' do

  purge = <<-EOS
   ceph::mon { 'a': ensure => absent }
   ->
   file { [
      '/var/lib/ceph/bootstrap-osd/ceph.keyring',
      '/etc/ceph/ceph.client.admin.keyring',
     ]:
     ensure => absent
   }
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
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='

  releases.each do |release|
    describe release do
      it 'should install one OSD no cephx' do
        pp = <<-EOS
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
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            authentication_type => 'none',
          }
          ->
          ceph::osd { '/dev/sdb': }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ceph osd tree' do |r|
          r.stdout.should =~ /osd.0/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall one osd' do
        shell 'ceph osd tree | grep DNE' do |r|
          r.exit_code.should_not be_zero
        end

        pp = <<-EOS
          ceph::osd { '/dev/sdb':
            ensure => absent,
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
        end

        shell 'ceph osd tree | grep DNE' do |r|
          r.exit_code.should be_zero
        end
        shell 'ceph-disk zap /dev/sdb'
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
      it 'should install one osd with cephx' do

        pp = <<-EOS
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
          exec { 'bootstrap-key':
            command => '/usr/sbin/ceph-create-keys --id a',
          }
          ->
          ceph::osd { '/dev/sdb': }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ceph osd tree' do |r|
          r.stdout.should =~ /osd.0/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall one osd' do
        shell 'ceph osd tree | grep DNE' do |r|
          r.exit_code.should_not be_zero
        end

        pp = <<-EOS
          ceph::osd { '/dev/sdb': ensure => absent, }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
        end

        shell 'ceph osd tree | grep DNE' do |r|
          r.exit_code.should be_zero
        end

        shell 'ceph-disk zap /dev/sdb'
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
      it 'should install one osd with external journal and no cephx' do
        pp = <<-EOS
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
          ceph::mon { 'a':
            public_addr => $::ipaddress_eth0,
            key => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
            authentication_type => 'none',
          }
          ->
          ceph::osd { '/dev/sdb':
            journal => '/tmp/journal'
          }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell 'ceph osd tree' do |r|
          r.stdout.should =~ /osd.0/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

      end

      it 'should uninstall one osd and external journal' do
        shell 'ceph osd tree | grep DNE' do |r|
          r.exit_code.should_not be_zero
        end

        pp = <<-EOS
          ceph::osd { '/dev/sdb': ensure => absent, }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
        end

        shell 'ceph osd tree | grep DNE' do |r|
          r.exit_code.should be_zero
        end
        shell 'ceph-disk zap /dev/sdb'
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
#   bundle exec rake spec:system SPEC=spec/system/ceph_osd_spec.rb &&
#   git checkout Gemfile
# "
# End:
