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
  shared_examples 'ceph pool' do
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
          :tag     => 'rbd',
        }
      end

      it {
        should contain_exec('create-volumes').with(
          :command => 'ceph osd pool create volumes 3',
          :path    => ['/bin', '/usr/bin'],
        )
        should contain_exec('set-volumes-pg_num').with(
          :command => 'ceph osd pool set volumes pg_num 3',
          :path    => ['/bin', '/usr/bin'],
        )
        should contain_exec('set-volumes-pgp_num').with(
          :command => 'ceph osd pool set volumes pgp_num 4',
          :path    => ['/bin', '/usr/bin'],
        ).that_requires('Exec[set-volumes-pg_num]')
        should contain_exec('set-volumes-size').with(
          :command => 'ceph osd pool set volumes size 2',
          :path    => ['/bin', '/usr/bin'],
        )
        should contain_exec('set-volumes-tag').with(
          :command => 'ceph osd pool application enable volumes rbd',
          :path    => ['/bin', '/usr/bin'],
        )
        should_not contain_exec('delete-volumes')
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
        should_not contain_exec('create-volumes')
        should contain_exec('delete-volumes').with(
          :command => 'ceph osd pool delete volumes volumes --yes-i-really-really-mean-it',
          :path    => ['/bin', '/usr/bin'],
        )
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

      it_behaves_like 'ceph pool'
    end
  end
end
