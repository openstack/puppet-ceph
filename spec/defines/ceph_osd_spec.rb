#
#   Copyright (C) 2014 Cloudwatt <libre.licensing@cloudwatt.com>
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
# Author: David Gurtner <aldavud@crimson.ch>
#

require 'spec_helper'

describe 'ceph::osd' do

  shared_examples_for 'ceph osd' do

    describe "with default params" do

      let :title do
        '/tmp'
      end

      it { should contain_exec('ceph-osd-prepare-/tmp').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if ! test -b /tmp ; then
  mkdir -p /tmp
fi
ceph-disk prepare  /tmp 
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | grep ' */tmp.*ceph data, prepared' ||
ceph-disk list | grep ' */tmp.*ceph data, active' ||
ls -l /var/lib/ceph/osd/ceph-* | grep ' /tmp'
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-/tmp').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if ! test -b /tmp ; then
  mkdir -p /tmp
fi
# activate happens via udev when using the entire device
if ! test -b /tmp || ! test -b /tmp1 ; then
  ceph-disk activate /tmp || true
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | grep ' */tmp.*ceph data, active' ||
ls -ld /var/lib/ceph/osd/ceph-* | grep ' /tmp'
",
        'logoutput' => true
      ) }
    end

    describe "with custom params" do

      let :title do
        '/tmp/data'
      end

      let :params do
        {
          :cluster => 'testcluster',
          :journal => '/tmp/journal',
        }
      end

      it { should contain_exec('ceph-osd-prepare-/tmp/data').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if ! test -b /tmp/data ; then
  mkdir -p /tmp/data
fi
ceph-disk prepare --cluster testcluster /tmp/data /tmp/journal
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | grep ' */tmp/data.*ceph data, prepared' ||
ceph-disk list | grep ' */tmp/data.*ceph data, active' ||
ls -l /var/lib/ceph/osd/testcluster-* | grep ' /tmp/data'
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-/tmp/data').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if ! test -b /tmp/data ; then
  mkdir -p /tmp/data
fi
# activate happens via udev when using the entire device
if ! test -b /tmp/data || ! test -b /tmp/data1 ; then
  ceph-disk activate /tmp/data || true
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | grep ' */tmp/data.*ceph data, active' ||
ls -ld /var/lib/ceph/osd/testcluster-* | grep ' /tmp/data'
",
        'logoutput' => true
      ) }
    end

    describe "with ensure absent" do

      let :title do
        '/tmp'
      end

      let :params do
        {
          :ensure => 'absent',
        }
      end

      it { should contain_exec('remove-osd-/tmp').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | grep ' */tmp.*ceph data' | sed -ne 's/.*osd.\\([0-9][0-9]*\\).*/\\1/p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | grep ' */tmp.*mounted on' | sed -ne 's/.*osd.\\([0-9][0-9]*\\)\$/\\1/p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ls -ld /var/lib/ceph/osd/ceph-* | grep ' /tmp' | sed -ne 's:.*/ceph-\\([0-9][0-9]*\\) -> .*:\\1:p' || true)
fi
if [ \"\$id\" ] ; then
  stop ceph-osd cluster=ceph id=\$id || true
  service ceph stop osd.\$id || true
  ceph  osd rm \$id
  ceph auth del osd.\$id
  rm -fr /var/lib/ceph/osd/ceph-\$id/*
  umount /var/lib/ceph/osd/ceph-\$id || true
  rm -fr /var/lib/ceph/osd/ceph-\$id
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | grep ' */tmp.*ceph data' | sed -ne 's/.*osd.\\([0-9][0-9]*\\).*/\\1/p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ceph-disk list | grep ' */tmp.*mounted on' | sed -ne 's/.*osd.\\([0-9][0-9]*\\)\$/\\1/p')
fi
if [ -z \"\$id\" ] ; then
  id=\$(ls -ld /var/lib/ceph/osd/ceph-* | grep ' /tmp' | sed -ne 's:.*/ceph-\\([0-9][0-9]*\\) -> .*:\\1:p' || true)
fi
if [ \"\$id\" ] ; then
  test ! -d /var/lib/ceph/osd/ceph-\$id
else
  true # if there is no id  we do nothing
fi
",
        'logoutput' => true
      ) }
    end
  end

  context 'Debian Family' do
    let :facts do
      {
        :osfamily => 'Debian',
      }
    end

    it_configures 'ceph osd'
  end

  context 'RedHat Family' do

    let :facts do
      {
        :osfamily => 'RedHat',
      }
    end

    it_configures 'ceph osd'
  end
end

# Local Variables:
# compile-command: "cd ../.. ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
