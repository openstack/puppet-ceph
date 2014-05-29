#
#   Copyright (C) 2014 Cloudwatt <libre.licensing@cloudwatt.com>
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

describe 'ceph::osd' do

  describe 'Debian Family' do

    let :facts do
      {
        :osfamily => 'Debian',
      }
    end

    describe "with custom params" do

      let :title do
        '/tmp'
      end

      it { should contain_exec('ceph-osd-mkfs-/tmp') }

    end
  end

  describe 'RedHat Family' do

    let :facts do
      {
        :osfamily => 'RedHat',
      }
    end

    describe "with custom params" do

      let :title do
        '/tmp'
      end

      it { should contain_exec('ceph-osd-mkfs-/tmp') }

    end
  end
end

# Local Variables:
# compile-command: "cd ../.. ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
