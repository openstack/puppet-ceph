#
#  Copyright (C) 2014 Nine Internet Solutions AG
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
#  Author: David Gurtner <aldavud@crimson.ch>
#
require 'spec_helper'

describe 'ceph::profile::client' do

  shared_examples_for 'ceph profile client' do
    it { should contain_ceph__key('client.admin').with(
      :secret       => 'AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA==',
      :keyring_path => '/etc/ceph/ceph.client.admin.keyring',
      :mode         => '0644')
    }
  end

  context 'on Debian' do

    let :facts do
      {
        :osfamily         => 'Debian',
        :lsbdistcodename  => 'wheezy',
        :operatingsystem  => 'Debian',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile client'
  end

  context 'on Ubuntu' do

    let :facts do
      {
        :osfamily         => 'Debian',
        :lsbdistcodename  => 'precise',
        :operatingsystem  => 'Ubuntu',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile client'
  end

  context 'on RHEL6' do

    let :facts do
      {
        :osfamily         => 'RedHat',
        :operatingsystem  => 'RHEL6',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile client'
  end
end
# Local Variables:
# compile-command: "cd ../.. ;
#    BUNDLE_PATH=/tmp/vendor bundle install ;
#    BUNDLE_PATH=/tmp/vendor bundle exec rake spec
# "
# End:
