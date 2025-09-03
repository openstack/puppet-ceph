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
    let :title do
      'volumes'
    end

    describe "create with custom params" do
      let :params do
        {
          :ensure      => 'present',
          :pg_num      => 4,
          :pgp_num     => 3,
          :size        => 2,
          :application => 'rbd',
        }
      end

      it {
        should contain_ceph_pool('volumes').with(
          :ensure      => 'present',
          :pg_num      => 4,
          :pgp_num     => 3,
          :size        => 2,
          :application => 'rbd',
        )
      }
    end

    describe "delete with custom params" do
      let :params do
        {
          :ensure => 'absent',
        }
      end

      it {
        should contain_ceph_pool('volumes').with(
          :ensure => 'absent'
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
