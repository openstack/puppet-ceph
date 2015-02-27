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

describe 'ceph::profile::client' do

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : [ 'dumpling', 'firefly', 'giant' ]
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  admin_key = 'AQA0TVRTsP/aHxAAFBvntu1dSEJHxtJeFFrRsg=='
  volumes_key = 'AQA4MPZTOGU0ARAAXH9a0fXxVq0X25n2yPREDw=='
  mon_key = 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg=='
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
      '/etc/ceph/ceph.client.admin.keyring',
      '/etc/ceph/ceph.client.volumes.keyring'
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
        it 'should install one monitor and one extra client on one host', :cephx do
          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::mon_key: '#{mon_key}'
ceph::profile::params::client_keys:
  'client.admin':
    secret: #{admin_key}
    mode: '0600'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: 'allow *'
  'client.volumes':
    secret: #{volumes_key}
    mode: '0644'
    user: 'root'
    group: 'root'
    cap_mon: 'allow r'
    cap_osd: 'allow class-read object_prefix rbd_children, allow rwx pool=volumes'
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
            include ::ceph::profile::client
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

          shell 'ceph -n client.volumes -s' do |r|
            r.stdout.should =~ /1 mons .* quorum 0 first/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          shell 'ceph auth list' do |r|
            r.stdout.should =~ /#{admin_key}/
            r.exit_code.should be_zero
          end

          shell 'ceph auth list' do |r|
            r.stdout.should =~ /#{volumes_key}/
            r.exit_code.should be_zero
          end
        end

        it 'should uninstall one monitor' do
          puppet_apply(purge) do |r|
            r.exit_code.should_not == 1
          end
        end
      end

      describe 'on two hosts' do
        it 'should install one monitor on first host, one client on second host', :cephx do
          ['first', 'second'].each do |vm|
            if vm == "first"
              hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::mon_key: '#{mon_key}'
ceph::profile::params::client_keys:
  'client.admin':
    secret: #{admin_key}
    mode: '0600'
    cap_mon: 'allow *'
    cap_osd: 'allow *'
    cap_mds: 'allow *'
  'client.volumes':
    secret: #{volumes_key}
    mode: '0644'
    user: 'root'
    group: 'root'
    cap_mon: 'allow r'
    cap_osd: 'allow class-read object_prefix rbd_children, allow rwx pool=volumes'
              EOS
            end

            if vm == "second"
              hiera = <<-EOS
ceph::profile::params::release: '#{release}'
ceph::profile::params::authentication_type: 'cephx'
ceph::profile::params::client_keys:
  'client.volumes':
    secret: #{volumes_key}
    mode: '0644'
    user: 'root'
    group: 'root'
    cap_mon: 'allow r'
    cap_osd: 'allow class-read object_prefix rbd_children, allow rwx pool=volumes'
              EOS
            end

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
                include ::ceph::profile::client
              EOS
            end

            puppet_apply(:node => vm, :code => pp) do |r|
              r.exit_code.should_not == 1
              r.refresh
              r.exit_code.should_not == 1
            end
          end

          ['first', 'second'].each do |vm|
            if vm == "first"
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

            if vm == "second"
              shell 'ceph -n client.volumes -s' do |r|
                r.stdout.should =~ /1 mons .* quorum 0 first/
                r.stderr.should be_empty
                r.exit_code.should be_zero
              end
            end
          end
        end

        it 'should uninstall one monitor' do
          [ 'second', 'first' ].each do |vm|
            puppet_apply(:node => vm, :code => purge) do |r|
              r.exit_code.should_not == 1
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
#   RELEASES=dumpling \
#   RS_SET=two-ubuntu-server-1204-x64 \
#   RS_DESTROY=no \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_profile_client_spec.rb &&
#   git checkout Gemfile
# "
# End:
