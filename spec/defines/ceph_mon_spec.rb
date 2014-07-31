#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
#
require 'spec_helper'

describe 'ceph::mon' do

  describe 'Debian Family' do

    describe "with custom params" do

      let :facts do
        {
          :osfamily => 'Debian',
          :operatingsystem => 'Ubuntu',
        }
      end

      let :title do
        'A'
      end

      let :params do
        {
          :public_addr  => '127.0.0.1',
          :authentication_type => 'none',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => "running") }
      it { should contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
         'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring"
       ) }

#      it { p subject.resources }

    end
  end

  describe 'Redhat Family' do

    describe "with custom params" do

      let :facts do
        {
          :osfamily => 'RedHat',
          :operatingsystem => 'RHEL6',
        }
      end

      let :title do
        'A'
      end

      let :params do
        {
          :public_addr  => '127.0.0.1',
          :authentication_type => 'none',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => "running") }
      it { should contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
         'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring"
       ) }

#      it { p subject.resources }

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
