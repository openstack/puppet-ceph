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

describe 'basic tests:' do

  # Using puppet_apply as a helper
  it 'ceph::repo should work with no errors' do
    pp = <<-EOS
      class { 'ceph::repo':
          release => 'dumpling'
        }
    EOS

    # Run it twice and test for idempotency
    puppet_apply(pp) do |r|
      r.exit_code.should_not == 1
      r.refresh
      r.exit_code.should be_zero
    end

  end

  context shell 'apt-cache policy ceph' do
    its(:stdout) { should =~ /Candidate: 0.67/ }
    its(:stderr) { should be_empty }
    its(:exit_code) { should be_zero }
  end

end
