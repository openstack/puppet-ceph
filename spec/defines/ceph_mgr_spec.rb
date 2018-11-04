# Copyright (C) 2017 VEXXHOST, Inc.
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
# Author: Mohammed Naser <mnaser@vexxhost.com>
#
require 'spec_helper'

describe 'ceph::mgr' do
  let (:title) { 'foo' }

  shared_examples 'ceph::mgr' do
    context 'with cephx configured but no key specified' do
      let :params do
        {
          :authentication_type => 'cephx'
        }
      end

      it { should raise_error(Puppet::Error, /cephx requires a specified key for the manager daemon/) }
    end

    context 'cephx authentication_type' do
      let :params do
        {
          :authentication_type => 'cephx',
          :key                 => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
        }
      end

      it { should contain_file('/var/lib/ceph/mgr').with(
        :ensure => 'directory',
        :owner  => 'ceph',
        :group  => 'ceph'
      )}

      it { should contain_file('/var/lib/ceph/mgr/ceph-foo').with(
        :ensure => 'directory',
        :owner  => 'ceph',
        :group  => 'ceph'
      )}

      it { should contain_ceph__key('mgr.foo').with(
        :secret       => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
        :cluster      => 'ceph',
        :keyring_path => '/var/lib/ceph/mgr/ceph-foo/keyring',
        :cap_mon      => 'allow profile mgr',
        :cap_osd      => 'allow *',
        :cap_mds      => 'allow *',
        :user         => 'ceph',
        :group        => 'ceph',
        :inject       => false,
      )}

      it { should contain_service('ceph-mgr@foo').with(
        :ensure => 'running',
        :enable => true,
      )}
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph::mgr'
    end
  end
end
