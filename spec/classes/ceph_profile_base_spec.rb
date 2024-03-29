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

describe 'ceph::profile::base' do

  shared_examples 'ceph profile base' do
    describe "with default params" do
      it { should contain_class('ceph::profile::params') }
      it { should contain_class('ceph::repo') }
      it { should contain_class('ceph') }
    end

    describe "with custom param manage_repo false" do
      let :pre_condition do
        "class { 'ceph::profile::params': manage_repo => false }"
      end
      it { should contain_class('ceph::profile::params') }
      it { should_not contain_class('ceph::repo') }
      it { should contain_class('ceph') }
    end
  end


  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph profile base'
    end
  end
end
