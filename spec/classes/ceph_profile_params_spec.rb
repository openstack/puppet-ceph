#
#  Copyright (C) 2015 iWeb Technologies Inc.
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
#  Author: David Moreau Simard <dmsimard@iweb.com>
#
require 'spec_helper'

describe 'ceph::profile::params' do

  shared_examples_for 'ceph profile params' do
    describe "should fail when client_keys is not a hash" do

      let :pre_condition do
        "class { 'ceph::profile::params':
          client_keys => 'client.admin'
        }"
      end

      it { is_expected.to raise_error Puppet::Error, /is not a Hash/ }
    end

    describe "should fail when using cephx without client_keys" do

      let :pre_condition do
        "class { 'ceph::profile::params':
          authentication_type => 'cephx',
          client_keys => {}
        }"
      end

      it { is_expected.to raise_error Puppet::Error,
        /client_keys must be provided when using authentication_type = 'cephx'/
      }
    end
  end

  context 'on Debian' do

    let :facts do
      {
        :osfamily        => 'Debian',
        :lsbdistcodename => 'wheezy'
      }
    end

    it_configures 'ceph profile params'
  end

  context 'on Ubuntu' do

    let :facts do
      {
        :osfamily        => 'Debian',
        :lsbdistcodename => 'Precise'
      }
    end

    it_configures 'ceph profile params'
  end

  context 'on RHEL6' do

    let :facts do
      { :osfamily => 'RedHat', }
    end

    it_configures 'ceph profile params'
  end
end
# Local Variables:
# compile-command: "cd ../.. ;
#    BUNDLE_PATH=/tmp/vendor bundle install ;
#    BUNDLE_PATH=/tmp/vendor bundle exec rake spec
# "
# End:
