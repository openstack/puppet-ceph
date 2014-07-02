#
#  Copyright (C) 2013,2014 Cloudwatt <libre.licensing@cloudwatt.com>
#  Copyright 2014 (C) Nine Internet Solutions AG
#
#  Author: Loic Dachary <loic@dachary.org>
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

describe 'ceph::repo' do

  release2version = {
    'dumpling' => '0.67',
    'emperor' => '0.72',
    'firefly' => '0.80',
    '(default)' => '0.80',
  }

  releases = ENV['RELEASES'] ? ENV['RELEASES'].split : release2version.keys

  # on RedHat family we need to remove with the correct release,
  # and at this point we do not know what is currently installed
  it 'should remove repo independent of release' do
    releases.each do |release|

      release_arg = release == '(default)' ? '' : "release => '#{release}',"
      pp = <<-EOS
        class { 'ceph::repo':
          #{release_arg}
          ensure  => absent,
        }
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should_not == 1
      end
    end

    osfamily = facter.facts['osfamily']

    if osfamily == 'Debian'
      shell 'apt-cache policy ceph' do |r|
        r.stdout.should_not =~ /ceph.com/
        r.stderr.should be_empty
        r.exit_code.should be_zero
      end
    end
    if osfamily == 'RedHat'
      shell 'yum info ceph' do |r|
        r.stdout.should_not =~ /ceph.com/
        r.stderr.should =~ /Error: No matching Packages to list/
        r.exit_code.should_not be_zero
      end
    end
  end

  releases.each do |release|

    release_arg = release == '(default)' ? '' : "release => '#{release}',"

    describe release do

      version = release2version[release]

      it "should find #{version}" do
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

        pp = <<-EOS
          class { 'ceph::repo':
            #{release_arg}
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        shell querycommand do |r|
          r.stdout.should =~ /#{queryresult}/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        # On RedHat family we need to use the version when removing
        pp = <<-EOS
          class { 'ceph::repo':
            ensure  => absent,
            #{release_arg}
          }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should_not == 1
        end

        if osfamily == 'Debian'
          shell querycommand do |r|
            r.stdout.should_not =~ /ceph.com/
            r.stderr.should be_empty
            r.exit_code.should be_zero
          end
        end
        if osfamily == 'RedHat'
          shell querycommand do |r|
            r.stdout.should_not =~ /ceph.com/
            r.stderr.should =~ /Error: No matching Packages to list/
            r.exit_code.should_not be_zero
          end
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
#   MACHINES=first \
#   RELEASES=dumpling \
#   RS_DESTROY=no \
#   RS_SET=one-ubuntu-server-12042-x64 \
#   BUNDLE_PATH=/tmp/vendor \
#   bundle exec rake spec:system SPEC=spec/system/ceph_repo_spec.rb &&
#   git checkout Gemfile
# "
# End:
