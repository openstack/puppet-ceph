#
#  Copyright 2013 Cloudwatt <libre-licensing@cloudwatt.com>
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

describe 'ceph::repo' do

  release2version = {
    'cuttlefish' => '0.61',
    'dumpling' => '0.67',
    'emperor' => '0.72',
    '(default)' => '0.72',
  }

  release2version.keys.each do |release|

    release_arg = release == '(default)' ? '' : "release => '#{release}'"

    describe release do

      version = release2version[release]

      it "should find #{version}" do
        pp = <<-EOS
         class { 'ceph::repo':
           ensure => absent
         }
        EOS

        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
        end

        shell 'apt-cache policy ceph' do |r|
          r.stdout.should_not =~ /ceph.com/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end

        pp = <<-EOS
         class { 'ceph::repo':
           #{release_arg}
         }
        EOS

        # Run it twice and test for idempotency
        puppet_apply(pp) do |r|
          r.exit_code.should_not == 1
          r.refresh
          r.exit_code.should be_zero
        end

        shell 'apt-cache policy ceph' do |r|
          r.stdout.should =~ /Candidate: #{version}/
          r.stderr.should be_empty
          r.exit_code.should be_zero
        end
      end
    end
  end
end
