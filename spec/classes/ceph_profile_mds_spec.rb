#
#  Copyright (C) 2016 Red Hat, Inc.
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
#  Author: Giulio Fidente <gfidente@redhat.com>
#
require 'spec_helper'

describe 'ceph::profile::mds' do

  shared_examples_for 'ceph profile mds' do

    it { is_expected.to contain_class('ceph::mds').with(
      'public_addr' => '10.11.12.2',
    )}
    it { is_expected.to contain_ceph__key('mds.myhostname').with(
      :cap_mon      => 'allow profile mds',
      :cap_osd      => 'allow rwx',
      :cap_mds      => 'allow',
      :inject       => true,
      :keyring_path => "/var/lib/ceph/mds/ceph-myhostname/keyring",
      :secret       => 'AQDLOh1VgEp6FRAAFzT7Zw+Y9V6JJExQAsRnRQ==',
      :user         => 'ceph',
      :group        => 'ceph'
    )}
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({:hostname => 'myhostname'}))
      end

      it_behaves_like 'ceph profile mds'
    end
  end
end
