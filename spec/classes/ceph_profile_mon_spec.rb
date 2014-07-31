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
    it { should contain_ceph__mon('first').with(
      :authentication_type => 'cephx',
      :key                 => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==')
    }
    it { should contain_ceph__key('client.admin').that_requires('Ceph::Mon[first]').with(
      :secret          => 'AQBMGHJTkC8HKhAAJ7NH255wYypgm1oVuV41MA==',
      :cap_mon         => 'allow *',
      :cap_osd         => 'allow *',
      :cap_mds         => 'allow',
      :mode            => '0644',
      :inject          => true,
      :inject_as_id    => 'mon.',
      :inject_keyring  => '/var/lib/ceph/mon/ceph-first/keyring')
    }
    it { should contain_ceph__key('client.bootstrap-osd').that_requires('Ceph::Mon[first]').with(
      :secret          => 'AQARG3JTsDDEHhAAVinHPiqvJkUi5Mww/URupw==',
      :keyring_path    => '/var/lib/ceph/bootstrap-osd/ceph.keyring',
      :cap_mon         => 'allow profile bootstrap-osd',
      :inject          => true,
      :inject_as_id    => 'mon.',
      :inject_keyring  => '/var/lib/ceph/mon/ceph-first/keyring')
    }
    it { should contain_ceph__key('client.bootstrap-mds').that_requires('Ceph::Mon[first]').with(
      :secret          => 'AQCztJdSyNb0NBAASA2yPZPuwXeIQnDJ9O8gVw==',
      :keyring_path    => '/var/lib/ceph/bootstrap-mds/ceph.keyring',
      :cap_mon         => 'allow profile bootstrap-mds',
      :inject          => true,
      :inject_as_id    => 'mon.',
      :inject_keyring  => '/var/lib/ceph/mon/ceph-first/keyring')
    }
  end

  context 'on Debian' do

    let :facts do
      {
        :osfamily         => 'Debian',
        :lsbdistcodename  => 'wheezy',
        :operatingsystem  => 'Debian',
        :hostname         => 'first',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile mon'
  end

  context 'on Ubuntu' do

    let :facts do
      {
        :osfamily         => 'Debian',
        :lsbdistcodename  => 'precise',
        :operatingsystem  => 'Ubuntu',
        :hostname         => 'first',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile mon'
  end

  context 'on RHEL6' do

    let :facts do
      {
        :osfamily         => 'RedHat',
        :operatingsystem  => 'RHEL6',
        :hostname         => 'first',
      }
    end

    # dont actually run any tests. these cannot run under puppet 2.7
    # TODO: uncomment once 2.7 is deprecated
    #it_configures 'ceph profile mon'
  end

end
# Local Variables:
# compile-command: "cd ../.. ;
#    BUNDLE_PATH=/tmp/vendor bundle install ;
#    BUNDLE_PATH=/tmp/vendor bundle exec rake spec
# "
# End:
