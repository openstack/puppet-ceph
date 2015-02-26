#
#  Copyright (C) 2014 Nine Internet Solutions AG
#
#  Author: David Gurtner <aldavud@crimson.ch>
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

describe 'ceph::profile::base' do

  release2version = {
    'dumpling' => '0.67',
    'firefly' => '0.80',
    'giant' => '0.87',
  }

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : release2version.keys
  machines = ENV['MACHINES'] ? ENV['MACHINES'].split : [ 'first', 'second' ]
  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"
  fsid = 'a4807c9a-e76f-4666-a297-6d6cbc922e3a'
  hieradata_common = '/var/lib/hiera/common.yaml'
  hiera_shared = <<-EOS
---
ceph::profile::params::fsid: '#{fsid}'
  EOS

  releases.each do |release|
    describe release do

      version = release2version[release]

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
        it 'should install ceph' do
          osfamily = facter.facts['osfamily']

          osfamily2querycommand = {
            'Debian' => 'apt-cache policy ceph',
            'RedHat' => 'yum info ceph',
          }
          osfamily2queryresult = {
            'Debian' => "Candidate: #{version}" ,
            'RedHat' => "Version     : #{version}",
          }

          querycommand = osfamily2querycommand[osfamily]
          queryresult = osfamily2queryresult[osfamily]

          hiera = <<-EOS
ceph::profile::params::release: '#{release}'
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
            include ::ceph::profile::base
          EOS

          puppet_apply(pp) do |r|
            r.exit_code.should_not == 1
            r.refresh
            r.exit_code.should_not == 1
          end

          shell 'cat /etc/ceph/ceph.conf' do |r|
            r.stdout.should =~ /#{fsid}/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end

          shell querycommand do |r|
            r.stdout.should =~ /#{queryresult}/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
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
#   bundle exec rake spec:system SPEC=spec/system/ceph_profile_base_spec.rb &&
#   git checkout Gemfile
# "
# End:
