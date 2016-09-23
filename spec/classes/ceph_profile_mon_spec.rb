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

describe 'ceph::profile::mon' do

  shared_examples_for 'ceph profile mon' do

    it { is_expected.to contain_ceph__mon('first').with(
      :authentication_type => 'cephx',
      :key                 => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
      :public_addr         => '10.11.12.2')
    }
    it { is_expected.to contain_class('ceph::keys').with(
      'args' => {
        'client.admin' => {
          'secret'  => 'AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA==',
          'mode'    => '0600',
          'cap_mon' => 'allow *',
          'cap_osd' => 'allow *',
          'cap_mds' => 'allow *'
        },
        'client.bootstrap-osd' => {
          'secret'       => 'AQARG3JTsDDEHhAAVinHPiqvJkUi5Mww/URupw==',
          'keyring_path' => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
          'cap_mon'      => 'allow profile bootstrap-osd'
        },
        'client.bootstrap-mds' => {
          'secret'       => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
          'keyring_path' => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
          'cap_mon'      => 'allow profile bootstrap-mds'
        },
        'client.volumes' => {
          'secret'  => 'AQA4MPZTOGU0ARAAXH9a0fXxVq0X25n2yPREDw==',
          'mode'    => '0644',
          'user'    => 'root',
          'group'   => 'root',
          'cap_mon' => 'allow r',
          'cap_osd' => 'allow class-read object_prefix rbd_children, allow rwx pool=volumes'
        }
      },
      'defaults' => {
        'inject'         => true,
        'inject_as_id'   => 'mon.',
        'inject_keyring' => '/var/lib/ceph/mon/ceph-first/keyring'
      }
    )}
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({:hostname => 'first'})
      end

      it_behaves_like 'ceph profile mon'
    end
  end
end
