#
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
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
#
require 'spec_helper'

describe 'ceph::conf' do
  let :params do
    {
      :args => {
        'A' => {
          'value' => 'AA VALUE',
        },
        'B' => { }
      },
      :defaults => {
        'value' => 'DEFAULT',
      },
    }
  end

  shared_examples 'ceph::conf' do
    context 'with specified parameters' do
      it {
        should contain_ceph_config('A').with_value('AA VALUE')
        should contain_ceph_config('B').with_value('DEFAULT')
      }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::conf'
    end
  end
end
