#
#  Copyright (C) Nine Internet Solutions AG
#
#  Author: David Gurtner <david@nine.ch>
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

describe 'ceph usecases' do

  # this test relies entirely on there being 2 machines with those exact names
  machines = [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  describe 'I want to try this module, heard of ceph, want to see it in action' do

    it 'should install one monitor and one OSD on /srv/data' do
      pp = <<-EOS
        class { 'ceph::repo': }
        class { 'ceph':
          fsid                       => generate('/usr/bin/uuidgen'),
          mon_host                   => $::ipaddress,
          authentication_type        => 'none',
          osd_pool_default_size      => '1',
          osd_pool_default_min_size  => '1',
        }
        ceph_config {
         'global/osd_journal_size': value => '100';
        }
        ceph::mon { 'a':
          public_addr         => $::ipaddress,
          authentication_type => 'none',
        }
        ceph::osd { '/srv/data': }
      EOS

      puppet_apply(pp) do |r|
        # due to the generate() the above is not idempotent
        # so we don't run twice as usual
        r.exit_code.should_not == 1
      end

      shell 'sleep 30' # we need to wait a bit until the OSD is up

      shell 'ceph -s' do |r|
        r.stdout.should =~ /1 mons at/
        r.stderr.should be_empty
        r.exit_code.should be_zero
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
        ceph::osd { '/srv/data':
          ensure => absent,
        }
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should_not == 1
      end

      shell 'ceph osd tree | grep DNE' do |r|
        r.stderr.should be_empty
        r.exit_code.should be_zero
      end
    end

    it 'should uninstall one monitor' do
      pp = <<-EOS
        ceph::mon { 'a':
          ensure => absent,
        }
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should_not == 1
      end

      osfamily = facter.facts['osfamily']
      operatingsystem = facter.facts['operatingsystem']

      if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
        shell 'status ceph-mon id=a' do |r|
          r.stdout.should be_empty
          r.stderr.should =~ /Unknown instance: ceph.a/
          r.exit_code.should_not be_zero
        end
      end
      if osfamily == 'RedHat'
        shell 'service ceph status mon.a' do |r|
          r.stdout.should =~ /mon.a not found/
          r.stderr.should be_empty
          r.exit_code.should_not be_zero
        end
      end
    end

    it 'should purge all packages' do
      pp = <<-EOS
        package { #{packages}:
          ensure => purged
        }
        class { 'ceph::repo':
          ensure  => absent,
        }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
        end
      end
    end
  end

  describe 'I want to operate a production cluster' do
    it 'should install one monitor with key and one OSD' do
      # this usecase is simplified to accomodate for the fact that
      # there are only 2 hosts availble for integration testing
      pp = <<-EOS
        $admin_key = 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ=='
        $mon_key = 'AQDesGZSsC7KJBAAw+W/Z4eGSQGAIbxWjxjvfw=='
        $bootstrap_osd_key = 'AQABsWZSgEDmJhAAkAGSOOAJwrMHrM5Pz5On1A=='
        $fsid = '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'

        node /first/ {
          class { 'ceph::repo': }
          class { 'ceph':
            fsid                => $fsid,
            mon_initial_members => 'first',
            mon_host            => '10.11.12.2',
          }
          ceph::mon { $::hostname:
            key => $mon_key,
          }
          Ceph::Key {
            inject         => true,
            inject_as_id   => 'mon.',
            inject_keyring => "/var/lib/ceph/mon/ceph-${::hostname}/keyring",
          }
          ceph::key { 'client.admin':
            secret  => $admin_key,
            cap_mon => 'allow *',
            cap_osd => 'allow *',
            cap_mds => 'allow',
          }
          ceph::key { 'client.bootstrap-osd':
            secret  => $bootstrap_osd_key,
            cap_mon => 'allow profile bootstrap-osd',
          }
        }

        node /second/ {
          class { 'ceph::repo': }
          class { 'ceph':
            fsid                => $fsid,
            mon_initial_members => 'first',
            mon_host            => '10.11.12.2',
          }
          ceph::osd { '/dev/sdb': }
          ceph::key{'client.bootstrap-osd':
             keyring_path => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
             secret       => $bootstrap_osd_key,
          }
          ceph::key { 'client.admin':
            secret => $admin_key
          }
        }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end
      end

      shell 'ceph -s' do |r|
        r.stdout.should =~ /1 mons at/
        r.stderr.should be_empty
        r.exit_code.should be_zero
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

      puppet_apply(:node => 'second', :code => pp) do |r|
        r.exit_code.should_not == 1
      end

      shell(:node => 'second', :command => "test -b /dev/sdb && ceph-disk zap /dev/sdb")

      shell 'ceph osd tree | grep DNE' do |r|
        r.exit_code.should be_zero
      end
    end

    it 'should uninstall one monitor' do
      pp = <<-EOS
        ceph::mon { 'first':
          ensure => absent,
        }
      EOS

      puppet_apply(:node => 'first', :code => pp) do |r|
        r.exit_code.should_not == 1
      end

      osfamily = facter.facts['osfamily']
      operatingsystem = facter.facts['operatingsystem']

      if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
        shell 'status ceph-mon id=first' do |r|
          r.stdout.should be_empty
          r.stderr.should =~ /Unknown instance: ceph.first/
          r.exit_code.should_not be_zero
        end
      end
      if osfamily == 'RedHat'
        shell 'service ceph status mon.first' do |r|
          r.stdout.should =~ /mon.first not found/
          r.stderr.should be_empty
          r.exit_code.should_not be_zero
        end
      end
    end

    it 'should purge all packages' do
      pp = <<-EOS
        package { #{packages}:
          ensure => purged
        }
        class { 'ceph::repo':
          ensure  => absent,
        }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
        end
      end
    end
  end

  describe 'I want to run benchmarks on three new machines' do
    it 'should install one monitor and two OSDs' do
      # contrary to the name we will only install two machines
      pp = <<-EOS
        $fsid = '066F558C-6789-4A93-AAF1-5AF1BA01A3AD'

        node /first/ {
          class { 'ceph::repo': }
          class { 'ceph':
            fsid                => $fsid,
            mon_host            => '10.11.12.2',
            mon_initial_members => 'first',
            authentication_type => 'none',
          }
          ceph::mon { $::hostname:
            authentication_type => 'none',
          }
          ceph::osd { '/dev/sdb': }
        }

        node /second/ {
          class { 'ceph::repo': }
          class { 'ceph':
            fsid                => $fsid,
            mon_host            => '10.11.12.2',
            mon_initial_members => 'first',
            authentication_type => 'none',
          }
          ceph::osd { '/dev/sdb': }
        }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end
      end

      shell 'ceph -s' do |r|
        r.stdout.should =~ /1 mons at/
        r.stderr.should be_empty
        r.exit_code.should be_zero
      end

      shell 'ceph osd tree' do |r|
        r.stdout.should =~ /osd.0/
        r.stdout.should =~ /osd.1/
        r.stderr.should be_empty
        r.exit_code.should be_zero
      end
    end

    it 'should uninstall two OSDs' do
      shell 'ceph osd tree | grep DNE' do |r|
        r.exit_code.should_not be_zero
      end

      pp = <<-EOS
        ceph::osd { '/dev/sdb':
          ensure => absent,
        }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
        end

        shell(:node => vm, :command => "test -b /dev/sdb && ceph-disk zap /dev/sdb")
      end

      shell 'ceph osd tree | grep DNE' do |r|
        r.exit_code.should be_zero
      end
    end

    it 'should uninstall one monitor' do
      pp = <<-EOS
        ceph::mon { 'first':
          ensure => absent,
        }
      EOS

      puppet_apply(:node => 'first', :code => pp) do |r|
        r.exit_code.should_not == 1
      end

      osfamily = facter.facts['osfamily']
      operatingsystem = facter.facts['operatingsystem']

      if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
        shell 'status ceph-mon id=first' do |r|
          r.stdout.should be_empty
          r.stderr.should =~ /Unknown instance: ceph.first/
          r.exit_code.should_not be_zero
        end
      end
      if osfamily == 'RedHat'
        shell 'service ceph status mon.first' do |r|
          r.stdout.should =~ /mon.first not found/
          r.stderr.should be_empty
          r.exit_code.should_not be_zero
        end
      end
    end

    it 'should purge all packages' do
      pp = <<-EOS
        package { #{packages}:
          ensure => purged
        }
        class { 'ceph::repo':
          ensure  => absent,
        }
      EOS

      machines.each do |vm|
        puppet_apply(:node => vm, :code => pp) do |r|
          r.exit_code.should_not == 1
        end
      end
    end
  end
end
# Local Variables:
# compile-command: "cd ../..
#   (
#     cd .rspec_system/vagrant_projects/two-ubuntu-server-1204-x64
#     vagrant destroy --force
#   )
#   cp -a Gemfile-rspec-system Gemfile
#   BUNDLE_PATH=/tmp/vendor bundle install --no-deployment
#   RS_DESTROY=no \
#   RS_SET=two-ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system \
#   SPEC=spec/system/ceph_usecases_spec.rb &&
#   git checkout Gemfile
# "
# End:
