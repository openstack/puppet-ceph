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

describe 'ceph::profile::osd' do

  shared_examples_for 'ceph profile osd' do
    context 'with the default osd defined in common.yaml' do

      before :each do
        facts.merge!( :hostname => 'osd')
      end

      it { is_expected.to contain_class('ceph::profile::client') }
      it { is_expected.to contain_ceph__osd('/dev/sdc').with(:journal => '/dev/sdb') }
      it { is_expected.to contain_ceph__osd('/dev/sdd').with(:journal => '/dev/sdb') }
    end

    context 'with the host specific first.yaml' do

      before :each do
        facts.merge!( :hostname => 'first')
      end

      it { is_expected.to contain_class('ceph::profile::client') }
      it { is_expected.to contain_ceph__osd('/dev/sdb').with( :journal => '/srv/journal') }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      it_behaves_like 'ceph profile osd'
    end
  end
end
