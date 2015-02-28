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

  it {
    is_expected.to contain_ceph_config('A').with('value' => "AA VALUE")
    is_expected.to contain_ceph_config('B').with('value' => "DEFAULT")
  }

end

# Local Variables:
# compile-command: "cd ../.. ;
#    export BUNDLE_PATH=/tmp/vendor ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
