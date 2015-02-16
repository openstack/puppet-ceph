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

  shared_examples_for 'ceph profile base' do
    describe "with default params" do
      it { is_expected.to contain_class('ceph::profile::params') }
      it { is_expected.to contain_class('ceph::repo') }
      it { is_expected.to contain_class('ceph') }
    end

    describe "with custom param manage_repo false" do
      let :pre_condition do
        "class { 'ceph::profile::params': manage_repo => false }"
      end
      it { is_expected.to contain_class('ceph::profile::params') }
      it { is_expected.to_not contain_class('ceph::repo') }
      it { is_expected.to contain_class('ceph') }
    end
  end

  context 'on Debian' do

    let :facts do
      {
        :osfamily        => 'Debian',
        :lsbdistcodename => 'wheezy'
      }
    end

    it_configures 'ceph profile base'
  end

  context 'on Ubuntu' do

    let :facts do
      {
        :osfamily        => 'Debian',
        :lsbdistcodename => 'Precise'
      }
    end

    it_configures 'ceph profile base'
  end

  context 'on RHEL6' do

    let :facts do
      { :osfamily => 'RedHat', }
    end

    it_configures 'ceph profile base'
  end
end
# Local Variables:
# compile-command: "cd ../.. ;
#    BUNDLE_PATH=/tmp/vendor bundle install ;
#    BUNDLE_PATH=/tmp/vendor bundle exec rake spec
# "
# End:
