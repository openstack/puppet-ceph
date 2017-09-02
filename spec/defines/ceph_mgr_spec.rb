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

  describe 'with cephx configured but no key specified' do
    let :params do
      {
        :authentication_type => 'cephx'
      }
    end

    it {
      is_expected.to raise_error(Puppet::Error, /cephx requires a specified key for the manager daemon/)
    }
  end

  describe 'cephx authentication_type' do
    let :params do
      {
        :authentication_type => 'cephx',
        :key                 => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
      }
    end

    it {
      is_expected.to contain_file('/var/lib/ceph/mgr').with(
        :ensure => 'directory',
        :owner  => 'ceph',
        :group  => 'ceph'
      )
    }

    it {
      is_expected.to contain_file('/var/lib/ceph/mgr/ceph-foo').with(
        :ensure => 'directory',
        :owner  => 'ceph',
        :group  => 'ceph'
      )
    }

    it {
      is_expected.to contain_ceph__key('mgr.foo').with(
        :secret       => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
        :cluster      => 'ceph',
        :keyring_path => "/var/lib/ceph/mgr/ceph-foo/keyring",
        :cap_mon      => 'allow profile mgr',
        :cap_osd      => 'allow *',
        :cap_mds      => 'allow *',
        :user         => 'ceph',
        :group        => 'ceph',
        :inject       => false,
      )
    }

    it {
      is_expected.to contain_service('ceph-mgr@foo').with(
        :ensure => 'running',
        :enable => true,
      )
    }
  end
end
