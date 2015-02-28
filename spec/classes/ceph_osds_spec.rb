#
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
# Author: David Gurtner <aldavud@crimson.ch>
#
require 'spec_helper'

describe 'ceph::osds' do

  shared_examples_for 'ceph osds' do
    let :params do
      {
        :args => {
          '/dev/sdb' => {
            'journal' => '/tmp/journal',
          },
          '/srv/data' => {
          },
        },
        :defaults => {
          'cluster' => 'CLUSTER',
        },
      }
    end

    it {
      is_expected.to contain_ceph__osd('/dev/sdb').with(
        :ensure  => 'present',
        :journal => '/tmp/journal',
        :cluster => 'CLUSTER'
    )
      is_expected.to contain_ceph__osd('/srv/data').with(
        :ensure  => 'present',
        :cluster => 'CLUSTER')
    }
  end

  describe 'Ubuntu' do
    let :facts do
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
      }
    end

    it_configures 'ceph osds'
  end

  describe 'Debian' do
    let :facts do
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Debian',
      }
    end

    it_configures 'ceph osds'
  end

  describe 'RedHat' do
    let :facts do
      {
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
      }
    end

    it_configures 'ceph osds'
  end
end

# Local Variables:
# compile-command: "cd ../..;
#    bundle install --path=vendor;
#    bundle exec rake spec
# "
# End:
