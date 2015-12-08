#
#  Copyright (C) 2015 David Gurtner
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
require 'spec_helper_acceptance'

describe 'ceph usecases' do

  # passing it directly as unqoted array is not supported everywhere
  packages = "[ 'python-ceph', 'ceph-common', 'librados2', 'librbd1', 'libcephfs1' ]"

  describe 'I want to try this module, heard of ceph, want to see it in action' do

    it 'should install one monitor and one OSD on /srv/data' do
      pp = <<-EOS
        class { 'ceph::repo': }
        class { 'ceph':
          fsid                       => '82274746-9a2c-426b-8c51-107fb0d890c6',
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

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)

      shell 'sleep 10' # we need to wait a bit until the OSD is up

      shell 'ceph -s', { :acceptable_exit_codes => [0] } do |r|
        expect(r.stdout).to match(/1 mons at/)
        expect(r.stderr).to be_empty
      end

      shell 'ceph osd tree', { :acceptable_exit_codes => [0] } do |r|
        expect(r.stdout).to match(/osd.0/)
        expect(r.stderr).to be_empty
      end
    end

    it 'should uninstall one osd' do
      shell 'ceph osd tree | grep DNE', { :acceptable_exit_codes => [1] }

      pp = <<-EOS
        ceph::osd { '/srv/data':
          ensure => absent,
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)

      shell 'sleep 10' # we need to wait a bit until the OSD is down

      shell 'ceph osd tree | grep DNE', { :acceptable_exit_codes => [0] }
    end

    it 'should uninstall one monitor' do
      pp = <<-EOS
        ceph::mon { 'a':
          ensure => absent,
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)

      osfamily = fact 'osfamily'
      operatingsystem = fact 'operatingsystem'

      if osfamily == 'Debian' && operatingsystem == 'Ubuntu'
        shell 'status ceph-mon id=a', { :acceptable_exit_codes => [1] } do |r|
          expect(r.stdout).to be_empty
          expect(r.stderr).to match(/Unknown instance: ceph.a/)
        end
      end
      if osfamily == 'RedHat'
        shell 'service ceph status mon.a', { :acceptable_exit_codes => [1] } do |r|
          expect(r.stdout).to match(/mon.a not found/)
          expect(r.stderr).to be_empty
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
        file { [
           '/var/lib/ceph',
           '/var/run/ceph',
           '/srv/data',
          ]:
          ensure => absent,
          recurse => true,
          purge => true,
          force => true,
        }

      EOS

      apply_manifest(pp, :catch_failures => true)
      # can't check for idempotency because of https://tickets.puppetlabs.com/browse/PUP-1198
      #apply_manifest(pp, :catch_changes => true)
      apply_manifest(pp, :catch_failures => true)
    end
  end
end
# Local Variables:
# compile-command: "cd ../..
#   BUNDLE_PATH=/tmp/vendor bundle install
#   BEAKER_set=ubuntu-server-1204-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rspec spec/acceptance/ceph_usecases_spec.rb
# "
# End:
