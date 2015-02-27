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
#
require 'spec_helper_system'

describe 'ceph::profile::osd' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  mon_key = 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg=='
  bootstrap_osd_key = 'AQARG3JTsDDEHhAAVinHPiqvJkUi5Mww/URupw=='
  hieradata_common = '/var/lib/hiera/common.yaml'
  hiera_shared = <<-EOS
---
ceph::profile::params::fsid: '#{fsid}'
ceph::profile::params::mon_initial_members: 'first'
ceph::profile::params::mon_host: '10.11.12.2:6789'
  EOS

  purge = <<-EOS
   ceph::mon { 'first': ensure => absent }
   ->
   file { [
      '/var/lib/ceph/bootstrap-osd/ceph.keyring',
      '/etc/ceph/ceph.client.admin.keyring',
     ]:
     ensure => absent
   }
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
        it 'should install one monitor and one osd' do
          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'none'
ceph::profile::params::osds:
  '/dev/sdb': {}
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
            include ::ceph::profile::osd
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

        it 'should uninstall one monitor' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should install one monitor and one osd with external journal' do
          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'none'
ceph::profile::params::osds:
  '/dev/sdb':
    journal: '/tmp/journal'
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
            include ::ceph::profile::osd
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

        it 'should uninstall one monitor' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should install one monitor and one osd', :cephx do
          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::mon_key: '#{mon_key}'
ceph::profile::params::osds:
  '/dev/sdb': {}
ceph::profile::params::client_keys:
  'client.admin':
    secret: #{admin_key}
    mode: '0600'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: 'allow *'
  'client.bootstrap-osd':
    secret: #{bootstrap_osd_key}
    keyring_path: '/var/lib/ceph/bootstrap-osd/ceph.keyring'
    cap_mon: 'allow profile bootstrap-osd'
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
            include ::ceph::profile::osd
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

      describe 'on two hosts' do
        it 'should install one monitor on first host, one osd on second host' do
          [ 'first', 'second' ].each do |vm|
            hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'none'
ceph::profile::params::osds:
  '/dev/sdb': {}
            EOS

            file = Tempfile.new('hieradata')
            begin
              file.write(hiera_shared + hiera)
              file.close
              rcp(:sp => file.path, :dp => hieradata_common, :d => node(:name => vm))
            ensure
              file.unlink
            end

            if vm == "first"
              pp = <<-EOS
                include ::ceph::profile::mon
              EOS
            end

            if vm == "second"
              pp = <<-EOS
                include ::ceph::profile::osd
              EOS
            end

            puppet_apply(:node => vm, :code => pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end
          end

          shell 'ceph -s' do |r|
            r.stdout.should =~ /1 mons .* quorum 0 first/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          shell 'ceph osd tree' do |r|
            r.stdout.should =~ /osd.0/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one osd on second host' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            ceph::osd { '/dev/sdb': ensure => absent, }
          EOS

          puppet_apply(:node => 'second', :code => pp) do |r|
            r.exit_code.should_not == 1
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end

          shell(:node => 'second', :command => 'ceph-disk zap /dev/sdb')

          puppet_apply(:node => 'second', :code => purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should uninstall one monitor on first host' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should install one monitor on first host, one osd on second host', :cephx do
          [ 'first', 'second' ].each do |vm|
            hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::mon_key: '#{mon_key}'
ceph::profile::params::osds:
  '/dev/sdb': {}
ceph::profile::params::client_keys:
  'client.admin':
    secret: #{admin_key}
    mode: '0600'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: 'allow *'
  'client.bootstrap-osd':
    secret: #{bootstrap_osd_key}
    keyring_path: '/var/lib/ceph/bootstrap-osd/ceph.keyring'
    cap_mon: 'allow profile bootstrap-osd'
            EOS

            file = Tempfile.new('hieradata')
            begin
              file.write(hiera_shared + hiera)
              file.close
              rcp(:sp => file.path, :dp => hieradata_common, :d => node(:name => vm))
            ensure
              file.unlink
            end

            if vm == "first"
              pp = <<-EOS
                include ::ceph::profile::mon
              EOS
            end

            if vm == "second"
              pp = <<-EOS
                include ::ceph::profile::osd
              EOS
            end

            puppet_apply(:node => vm, :code => pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end
          end

          shell 'ceph -s' do |r|
            r.stdout.should =~ /1 mons .* quorum 0 first/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          shell 'ceph osd tree' do |r|
            r.stdout.should =~ /osd.0/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one osd on second host' do
          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should_not be_zero
          end

          pp = <<-EOS
            # for osd removal we need additional credentials
            # not included in the bootstrap-osd keyring
            class { '::ceph::profile::client': } ->
            ceph::osd { '/dev/sdb': ensure => absent, }
          EOS

          puppet_apply(:node => 'second', :code => pp) do |r|
            r.exit_code.should_not == 1
          end

          shell 'ceph osd tree | grep DNE' do |r|
            r.exit_code.should be_zero
          end

          shell(:node => 'second', :command => 'ceph-disk zap /dev/sdb')

          puppet_apply(:node => 'second', :code => purge) do |r|
            r.exit_code.should_not == 1
          end
        end

        it 'should uninstall one monitor' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
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
#   RELEASES=dumpling \
#   RS_SET=two-ubuntu-server-1204-x64 \
#   RS_DESTROY=no \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_profile_osd_spec.rb &&
#   git checkout Gemfile
# "
# End:
