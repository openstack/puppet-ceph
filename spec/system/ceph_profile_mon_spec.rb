#
#  Copyright 2014 (C) Nine Internet Solutions AG
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
#  Author: David Gurtner <aldavud@crimson.ch>
#  Author: David Moreau Simard <dmsimard@iweb.com>
#
require 'spec_helper_system'

describe 'ceph::profile::mon' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  admin_key = 'AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA=='
  mon_key = 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg=='
  hieradata_common = '/var/lib/hiera/common.yaml'
  hiera_shared = <<-EOS
---
ceph::profile::params::fsid: '#{fsid}'
  EOS

  releases.each do |release|
    describe release do
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

        machines.each do |vm|
          puppet_apply(:node => vm, :code => pp) do |r|
            r.exit_code.should_not == 1
          end
        end
      end

      describe 'on one host' do
        it 'should install one monitor' do
          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'none'
ceph::profile::params::mon_initial_members: 'first'
ceph::profile::params::mon_host: '10.11.12.2:6789'
           EOS

           file = Tempfile.new('hieradata')
           begin
             file.write(hiera_shared + hiera)
             file.close
             rcp(:sp => file.path, :dp => hieradata_common, :d => node)
           ensure
             file.unlink
           end

           pp = <<-EOS
             include ::ceph::profile::mon
           EOS

           puppet_apply(pp) do |r|
             r.exit_code.should_not == 1
             r.refresh
             r.exit_code.should_not == 1
           end

           shell 'ceph -s' do |r|
             r.stdout.should =~ /1 mons .* quorum 0 first/
             r.stderr.should be_empty
             r.exit_code.should be_zero
           end
        end

        it 'should uninstall one monitor' do
         pp = <<-EOS
           ceph::mon { 'first':
             ensure => absent,
           }
         EOS

         puppet_apply(pp) do |r|
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
      end

      describe 'on one host', :cephx do
        it 'should install one monitor with key' do
          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::mon_key: '#{mon_key}'
ceph::profile::params::mon_initial_members: 'first'
ceph::profile::params::mon_host: '10.11.12.2:6789'
ceph::profile::params::client_keys:
  'client.admin':
    secret: #{admin_key}
    mode: '0600'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: 'allow *'
          EOS

          file = Tempfile.new('hieradata')
          begin
            file.write(hiera_shared + hiera)
            file.close
            rcp(:sp => file.path, :dp => hieradata_common, :d => node)
          ensure
            file.unlink
          end

          pp = <<-EOS
            include ::ceph::profile::mon
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end

          shell 'ceph -s' do |r|
            r.stdout.should =~ /1 mons .* quorum 0 first/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          shell 'ceph auth list' do |r|
            r.stdout.should =~ /#{admin_key}/
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one monitor' do
          pp = <<-EOS
            ceph::mon { 'first':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
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

        it 'should install one monitor with keyring' do
          key = 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw=='
          keyring = "[mon.]\\n\\tkey = #{key}\\n\\tcaps mon = \"allow *\""
          keyring_path = "/tmp/keyring"
          shell "echo -e '#{keyring}' > #{keyring_path}"

          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::mon_keyring: '#{keyring_path}'
ceph::profile::params::mon_initial_members: 'first'
ceph::profile::params::mon_host: '10.11.12.2:6789'
ceph::profile::params::client_keys:
  'client.admin':
    secret: #{admin_key}
    mode: '0600'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: 'allow *'
          EOS

          file = Tempfile.new('hieradata')
          begin
            file.write(hiera_shared + hiera)
            file.close
            rcp(:sp => file.path, :dp => hieradata_common, :d => node)
          ensure
            file.unlink
          end

          pp = <<-EOS
            include ::ceph::profile::mon
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end
          shell 'ceph -s' do |r|
            r.stdout.should =~ /1 mons .* quorum 0 first/

            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          shell 'ceph auth list' do |r|
            r.stdout.should =~ /#{admin_key}/
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one monitor' do
          pp = <<-EOS
            ceph::mon { 'first':
              ensure => absent,
            }
          EOS

          puppet_apply(pp) do |r|
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
      end

      describe 'on two hosts' do
        it 'should be two hosts' do
          machines.size.should == 2
        end

        it 'should install two monitors' do
          [ 'first', 'second' ].each do |mon|
            hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'none'
ceph::profile::params::public_network: '10.11.12.0/24'
ceph::profile::params::mon_initial_members: 'first, second'
ceph::profile::params::mon_host: '10.11.12.2,10.11.12.3'
            EOS

            file = Tempfile.new('hieradata')
            begin
              file.write(hiera_shared + hiera)
              file.close
              rcp(:sp => file.path, :dp => hieradata_common, :d => node(:name => mon))
            ensure
              file.unlink
            end

            pp = <<-EOS
            include ::ceph::profile::mon
            EOS

            puppet_apply(:node => mon, :code => pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end
          end

          shell 'ceph -s' do |r|
            r.stdout.should =~ /2 mons .* quorum 0,1 first,second/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall two monitors' do
          machines.each do |mon|
            pp = <<-EOS
              ceph::mon { '#{mon}':
                ensure => absent,
              }
            EOS

            puppet_apply(:node => mon, :code => pp) do |r|
              r.exit_code.should_not == 1
            end

            osfamily = facter.facts['osfamily']
            operatingsystem = facter.facts['operatingsystem']

            if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
              shell "status ceph-mon id=#{mon}" do |r|
                r.stdout.should be_empty
                r.stderr.should =~ /Unknown instance: ceph.#{mon}/
                r.exit_code.should_not be_zero
              end
            end
            if osfamily == 'RedHat'
              shell "service ceph status mon.#{mon}" do |r|
                r.stdout.should =~ /mon.#{mon} not found/
                r.stderr.should be_empty
                r.exit_code.should_not be_zero
              end
            end
          end
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
#   MACHINES='first second' \
#   RELEASES=dumpling \
#   RS_DESTROY=no \
#   RS_SET=two-ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system \
#          SPEC=spec/system/ceph_profile_mon_spec.rb \
#          SPEC_OPTS='--tag cephx' &&
#   git checkout Gemfile
# "
# End:
