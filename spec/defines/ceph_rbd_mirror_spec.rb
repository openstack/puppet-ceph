#   Copyright (C) 2016 Keith Schincke
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
# Author: Keith Schincke <keith.schincke@gmail.com>
#
require 'spec_helper'

describe 'ceph::mirror' do

  context 'Ubuntu 16.04' do

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '16.04',
        :service_provider       => 'systemd',
      }
    end

    describe 'with default params' do
      let :title do
        'A'
      end

      it { is_expected.to contain_service('ceph-rbd-mirror@A').with('ensure' => 'running') }

    end
  end

  context 'RHEL 7' do

    let :facts do
      {
        :osfamily                  => 'RedHat',
        :operatingsystem           => 'RedHat',
        :operatingsystemrelease    => '7.2',
        :operatingsystemmajrelease => '7',
        :service_provider          => 'systemd',
      }
    end

    describe 'with default params' do

      let :title do
        'A'
      end

      it { is_expected.to contain_service('ceph-rbd-mirror@A').with('ensure' => 'running') }

    end
  end
end
