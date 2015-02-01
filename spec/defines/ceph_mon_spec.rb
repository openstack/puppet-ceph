#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
#   Copyright (C) 2014 Nine Internet Solutions AG
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
# Author: Loic Dachary <loic@dachary.org>
# Author: David Moreau Simard <dmsimard@iweb.com>
# Author: David Gurtner <aldavud@crimson.ch>
#
require 'spec_helper'

describe 'ceph::mon' do

  context 'Ubuntu' do

    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
      }
    end

    describe 'with default params' do

      let :title do
        'A'
      end

      it {
        expect {
          should contain_service('ceph-mon-A').with('ensure' => 'running')
        }.to raise_error(Puppet::Error, /authentication_type cephx requires either key or keyring to be set but both are undef/)
      }
    end

    describe 'with key' do

      let :title do
        'A'
      end

      let :params do
        {
          :key => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { should contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { should contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon  \
         \
        --mkfs \
        --id A \
        --keyring /tmp/ceph-mon-keyring-A ; then
    touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        'logoutput' => true) }
      it { should contain_file('/tmp/ceph-mon-keyring-A').with(
        'mode' => '0444',
        'content' => "[mon.]\n\tkey = AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==\n\tcaps mon = \"allow *\"\n") }
      it { should contain_exec('rm-keyring-A').with('command' => '/bin/rm /tmp/ceph-mon-keyring-A') }
    end

    describe 'with keyring' do

      let :title do
        'A'
      end

      let :params do
        {
          :keyring => '/etc/ceph/ceph.mon.keyring',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { should contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { should contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon  \
         \
        --mkfs \
        --id A \
        --keyring /etc/ceph/ceph.mon.keyring ; then
    touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        'logoutput' => true) }
    end

    describe 'with custom params' do

      let :title do
        'A'
      end

      let :params do
        {
          :public_addr         => '127.0.0.1',
          :authentication_type => 'none',
          :cluster             => 'testcluster',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { should contain_exec('ceph-mon-testcluster.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/testcluster.client.admin.keyring'
       ) }
      it { should contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon --cluster testcluster \
        --public_addr 127.0.0.1 \
        --mkfs \
        --id A \
        --keyring /dev/null ; then
    touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        'logoutput' => true) }
    end

    describe 'with ensure absent' do

      let :title do
        'A'
      end

      let :params do
        {
          :ensure              => 'absent',
          :public_addr         => '127.0.0.1',
          :authentication_type => 'none',
          :cluster             => 'testcluster',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'stopped') }
      it { should contain_exec('remove-mon-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
rm -fr \$mon_data
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
which ceph-mon || exit 0 # if ceph-mon is not available we already uninstalled ceph and there is nothing to do
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
test ! -d \$mon_data
",
        'logoutput' => true) }
    end
  end

  context 'RHEL6' do

    let :facts do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RHEL6',
      }
    end

    describe 'with default params' do

      let :title do
        'A'
      end

      it {
        expect {
          should contain_service('ceph-mon-A').with('ensure' => 'running')
        }.to raise_error(Puppet::Error, /authentication_type cephx requires either key or keyring to be set but both are undef/)
      }
    end

    describe 'with key' do

      let :title do
        'A'
      end

      let :params do
        {
          :key => 'AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { should contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { should contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon  \
         \
        --mkfs \
        --id A \
        --keyring /tmp/ceph-mon-keyring-A ; then
    touch \$mon_data/done \$mon_data/sysvinit \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        'logoutput' => true) }
      it { should contain_file('/tmp/ceph-mon-keyring-A').with(
        'mode' => '0444',
        'content' => "[mon.]\n\tkey = AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==\n\tcaps mon = \"allow *\"\n") }
      it { should contain_exec('rm-keyring-A').with('command' => '/bin/rm /tmp/ceph-mon-keyring-A') }
    end

    describe 'with keyring' do

      let :title do
        'A'
      end

      let :params do
        {
          :keyring => '/etc/ceph/ceph.mon.keyring',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { should contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { should contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon  \
         \
        --mkfs \
        --id A \
        --keyring /etc/ceph/ceph.mon.keyring ; then
    touch \$mon_data/done \$mon_data/sysvinit \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        'logoutput' => true) }
    end

    describe 'with custom params' do

      let :title do
        'A'
      end

      let :params do
        {
          :public_addr         => '127.0.0.1',
          :authentication_type => 'none',
          :cluster             => 'testcluster',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { should contain_exec('ceph-mon-testcluster.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/testcluster.client.admin.keyring'
       ) }
      it { should contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
  mkdir -p \$mon_data
  if ceph-mon --cluster testcluster \
        --public_addr 127.0.0.1 \
        --mkfs \
        --id A \
        --keyring /dev/null ; then
    touch \$mon_data/done \$mon_data/sysvinit \$mon_data/keyring
  else
    rm -fr \$mon_data
  fi
fi
",
        'logoutput' => true) }
    end

    describe 'with ensure absent' do

      let :title do
        'A'
      end

      let :params do
        {
          :ensure              => 'absent',
          :public_addr         => '127.0.0.1',
          :authentication_type => 'none',
          :cluster             => 'testcluster',
        }
      end

      it { should contain_service('ceph-mon-A').with('ensure' => 'stopped') }
      it { should contain_exec('remove-mon-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
rm -fr \$mon_data
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
which ceph-mon || exit 0 # if ceph-mon is not available we already uninstalled ceph and there is nothing to do
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
test ! -d \$mon_data
",
        'logoutput' => true) }
    end
  end
end

# Local Variables:
# compile-command: "cd ../.. ;
#    export BUNDLE_PATH=/tmp/vendor ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
