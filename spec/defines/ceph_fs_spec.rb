# Copyright 2016 Red Hat, Inc.
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

require 'spec_helper'

describe 'ceph::fs' do

  shared_examples_for 'ceph fs' do
    describe "activated with custom params" do
      let :title do
        'fsa'
      end

      let :params do
        {
          :metadata_pool => 'metadata_pool',
          :data_pool     => 'data_pool'
        }
      end

      it { is_expected.to contain_exec('create-fs-fsa').with(
          :command =>  "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph fs new fsa metadata_pool data_pool",
          :unless  => "/bin/true # comment to satisfy puppet syntax requirements\nset -ex\nceph fs ls | grep 'name: fsa,'"
      )}
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({:hostname => 'myhostname'}))
      end

      it_behaves_like 'ceph fs'
    end
  end

end
