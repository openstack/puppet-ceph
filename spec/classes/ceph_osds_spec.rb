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

  shared_examples 'ceph osds' do
    let :params do
      {
        :args => {
          '/dev/sdb' => {
            'journal' => '/srv/journal',
          },
          '/srv/data' => {
          },
        },
        :defaults => {
          'cluster' => 'CLUSTER',
          'fsid'    => 'f39ace04-f967-4c3d-9fd2-32af2d2d2cd5',
        },
      }
    end

    it {
      should contain_ceph__osd('/dev/sdb').with(
        :ensure  => 'present',
        :journal => '/srv/journal',
        :cluster => 'CLUSTER',
        :fsid    => 'f39ace04-f967-4c3d-9fd2-32af2d2d2cd5')
      should contain_ceph__osd('/srv/data').with(
        :ensure  => 'present',
        :cluster => 'CLUSTER',
        :fsid    => 'f39ace04-f967-4c3d-9fd2-32af2d2d2cd5')
    }
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph osds'
    end
  end

end
