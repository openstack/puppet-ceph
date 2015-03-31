#
# Copyright (C) 2014 Catalyst IT Limited.
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
# Author: Ricardo Rocha <ricardo@catalyst.net.nz>
#

require 'spec_helper'

describe 'ceph::pool' do

  shared_examples_for 'ceph pool' do
    describe "create with custom params" do

      let :title do
        'volumes'
      end

      let :params do
        {
          :ensure  => 'present',
          :pg_num  => 3,
          :pgp_num => 4,
          :size    => 2,
        }
      end

      it {
        is_expected.to contain_exec('create-volumes').with(
          'command' => "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph osd pool create volumes 3"
        )
        is_expected.to contain_exec('set-volumes-pg_num').with(
          'command' => "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph osd pool set volumes pg_num 3"
        )
        is_expected.to contain_exec('set-volumes-pgp_num').with(
          'command' => "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph osd pool set volumes pgp_num 4"
        )
        is_expected.to contain_exec('set-volumes-size').with(
          'command' => "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph osd pool set volumes size 2"
        )
        is_expected.not_to contain_exec('delete-volumes')
      }

    end

    describe "delete with custom params" do

      let :title do
        'volumes'
      end

      let :params do
        {
          :ensure => 'absent',
        }
      end

      it {
        is_expected.not_to contain_exec('create-volumes')
        is_expected.to contain_exec('delete-volumes').with(
          'command' => "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph osd pool delete volumes volumes --yes-i-really-really-mean-it"
        )
      }

    end
  end

  describe 'Debian Family' do

    let :facts do
      {
        :osfamily => 'Debian',
      }
    end

    it_configures 'ceph pool'
  end

  describe 'RedHat Family' do

    let :facts do
      {
        :osfamily => 'RedHat',
      }
    end

    it_configures 'ceph pool'
  end
end

# Local Variables:
# compile-command: "cd ../.. ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
