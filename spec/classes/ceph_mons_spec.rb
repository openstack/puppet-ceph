#
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: Loic Dachary <loic@dachary.org>
# Author: David Gurtner <aldavud@crimson.ch>
#
require 'spec_helper'

describe 'ceph::mons' do

  shared_examples_for 'ceph mons' do
    let :params do
      {
        :args => {
          'A' => {
            'public_addr' => '1.2.3.4',
            'authentication_type' => 'none',
          },
          'B' => {
            'public_addr' => '1.2.3.4',
            'authentication_type' => 'none',
          },
        },
        :defaults => {
          'cluster' => 'CLUSTER',
        },
      }
    end

    it {
      is_expected.to contain_service('ceph-mon-A').with('ensure' => "running")
      is_expected.to contain_service('ceph-mon-B').with('ensure' => "running")
    }
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph mons'
    end
  end

end

# Local Variables:
# compile-command: "cd ../.. ;
#    export BUNDLE_PATH=/tmp/vendor ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
