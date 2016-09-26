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

  context 'Ubuntu 14.04' do

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '14.04',
        :service_provider       => 'upstart',
      }
    end

    describe 'with default params' do

      let :title do
        'A'
      end

      it {
        expect {
          is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running')
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_exec('create-keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
cat > /tmp/ceph-mon-keyring-A << EOF
[mon.]
    key = AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==
    caps mon = "allow *"
EOF

chmod 0444 /tmp/ceph-mon-keyring-A
',
        'unless' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=$(ceph-mon  --id A --show-config-value mon_data) || exit 1
# if ceph-mon fails then the mon is probably not configured yet
test -e $mon_data/done
') }
      it { is_expected.to contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon  \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /tmp/ceph-mon-keyring-A ; then
            touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/upstart \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon  \
              --mkfs \
              --id A \
              --keyring /tmp/ceph-mon-keyring-A ; then
            touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    fi
fi
",
        'logoutput' => true) }
      it { is_expected.to contain_exec('rm-keyring-A').with('command' => '/bin/rm /tmp/ceph-mon-keyring-A') }
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon  \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /etc/ceph/ceph.mon.keyring ; then
            touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/upstart \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon  \
              --mkfs \
              --id A \
              --keyring /etc/ceph/ceph.mon.keyring ; then
            touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_ceph_config('mon.A/public_addr').with_value("127.0.0.1") }
      it { is_expected.to contain_exec('ceph-mon-testcluster.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/testcluster.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon --cluster testcluster \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /dev/null ; then
            touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/upstart \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon --cluster testcluster \
              --mkfs \
              --id A \
              --keyring /dev/null ; then
            touch \$mon_data/done \$mon_data/upstart \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'stopped') }
      it { is_expected.to contain_exec('remove-mon-A').with(
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

      it {
        expect {
          is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running')
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_exec('create-keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
cat > /tmp/ceph-mon-keyring-A << EOF
[mon.]
    key = AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==
    caps mon = "allow *"
EOF

chmod 0444 /tmp/ceph-mon-keyring-A
',
        'unless' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=$(ceph-mon  --id A --show-config-value mon_data) || exit 1
# if ceph-mon fails then the mon is probably not configured yet
test -e $mon_data/done
') }
      it { is_expected.to contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon  \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /tmp/ceph-mon-keyring-A ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon  \
              --mkfs \
              --id A \
              --keyring /tmp/ceph-mon-keyring-A ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    fi
fi
",
        'logoutput' => true) }
      it { is_expected.to contain_exec('rm-keyring-A').with('command' => '/bin/rm /tmp/ceph-mon-keyring-A') }
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon  \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /etc/ceph/ceph.mon.keyring ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon  \
              --mkfs \
              --id A \
              --keyring /etc/ceph/ceph.mon.keyring ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_ceph_config('mon.A/public_addr').with_value("127.0.0.1") }
      it { is_expected.to contain_exec('ceph-mon-testcluster.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/testcluster.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon --cluster testcluster \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /dev/null ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon --cluster testcluster \
              --mkfs \
              --id A \
              --keyring /dev/null ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'stopped') }
      it { is_expected.to contain_exec('remove-mon-A').with(
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

  context 'RHEL7' do

    let :facts do
      {
        :osfamily         => 'RedHat',
        :operatingsystem  => 'RHEL7',
        :service_provider => 'systemd',
      }
    end

    describe 'with default params' do

      let :title do
        'A'
      end

      it {
        expect {
          is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running')
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_exec('create-keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
cat > /tmp/ceph-mon-keyring-A << EOF
[mon.]
    key = AQATGHJTUCBqIBAA7M2yafV1xctn1pgr3GcKPg==
    caps mon = "allow *"
EOF

chmod 0444 /tmp/ceph-mon-keyring-A
',
        'unless' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=$(ceph-mon  --id A --show-config-value mon_data) || exit 1
# if ceph-mon fails then the mon is probably not configured yet
test -e $mon_data/done
') }
      it { is_expected.to contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring',
        'unless'  => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
test -e /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon  \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /tmp/ceph-mon-keyring-A ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon  \
              --mkfs \
              --id A \
              --keyring /tmp/ceph-mon-keyring-A ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    fi
fi
",
        'logoutput' => true) }
      it { is_expected.to contain_exec('rm-keyring-A').with(
          'command' => '/bin/rm /tmp/ceph-mon-keyring-A',
          'unless'  => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
test ! -e /tmp/ceph-mon-keyring-A
') }
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_exec('ceph-mon-ceph.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/ceph.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon  --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon  \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /etc/ceph/ceph.mon.keyring ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon  \
              --mkfs \
              --id A \
              --keyring /etc/ceph/ceph.mon.keyring ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'running') }
      it { is_expected.to contain_ceph_config('mon.A/public_addr').with_value("127.0.0.1") }
      it { is_expected.to contain_exec('ceph-mon-testcluster.client.admin.keyring-A').with(
        'command' => '/bin/true # comment to satisfy puppet syntax requirements
set -ex
touch /etc/ceph/testcluster.client.admin.keyring'
       ) }
      it { is_expected.to contain_exec('ceph-mon-mkfs-A').with(
        'command' => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
mon_data=\$(ceph-mon --cluster testcluster --id A --show-config-value mon_data)
if [ ! -d \$mon_data ] ; then
    mkdir -p \$mon_data
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph \$mon_data
        if ceph-mon --cluster testcluster \
              --setuser ceph --setgroup ceph \
              --mkfs \
              --id A \
              --keyring /dev/null ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
            chown -h ceph:ceph \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
    else
        if ceph-mon --cluster testcluster \
              --mkfs \
              --id A \
              --keyring /dev/null ; then
            touch \$mon_data/done \$mon_data/systemd \$mon_data/keyring
        else
            rm -fr \$mon_data
        fi
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

      it { is_expected.to contain_service('ceph-mon-A').with('ensure' => 'stopped') }
      it { is_expected.to contain_exec('remove-mon-A').with(
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

    describe "with ensure set with bad value" do

      let :title do
        'A'
      end

      let :params do
        {
          :ensure => 'badvalue',
        }
      end

      it { is_expected.to raise_error(Puppet::Error, /Ensure on MON must be either present or absent/) }
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
