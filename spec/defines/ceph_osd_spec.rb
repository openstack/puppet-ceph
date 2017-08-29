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
        '/srv'
      end

      it { is_expected.to contain_exec('ceph-osd-check-udev-/srv').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
# Before Infernalis the udev rules race causing the activation to fail so we
# disable them. More at: http://www.spinics.net/lists/ceph-devel/msg28436.html
mv -f /usr/lib/udev/rules.d/95-ceph-osd.rules /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && udevadm control --reload || true
",
       'onlyif'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
DISABLE_UDEV=$(ceph --version | awk 'match(\$3, /[0-9]+\\.[0-9]+/) {if (substr(\$3, RSTART, RLENGTH) <= 0.94) {print 1}}')
test -f /usr/lib/udev/rules.d/95-ceph-osd.rules && test \$DISABLE_UDEV -eq 1
",
       'logoutput' => true,
      ) }
      it { is_expected.to contain_exec('ceph-osd-prepare-/srv').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
ceph-disk prepare --cluster ceph  $(readlink -f /srv) $(readlink -f '')
udevadm settle
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv)
ceph-disk list | egrep \" *(${disk}1?|${disk}p1?) .*ceph data, (prepared|active)\" ||
{ test -f $disk/fsid && test -f $disk/ceph_fsid && test -f $disk/magic ;}
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-activate-/srv').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
# activate happens via udev when using the entire device
if ! test -b \$disk && ! ( test -b \${disk}1 || test -b \${disk}p1 ); then
  ceph-disk activate $disk || true
fi
if test -f /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && ( test -b ${disk}1 || test -b ${disk}p1 ); then
  ceph-disk activate ${disk}1 || true
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | egrep \" *(\${disk}1?|\${disk}p1?) .*ceph data, active\" ||
ls -ld /var/lib/ceph/osd/ceph-* | grep \" $(readlink -f /srv)\$\"
",
        'logoutput' => true
      ) }
    end

    describe "with custom params" do

      let :title do
        '/srv/data'
      end

      let :params do
        {
          :cluster => 'testcluster',
          :journal => '/srv/journal',
          :fsid    => 'f39ace04-f967-4c3d-9fd2-32af2d2d2cd5',
        }
      end

      it { is_expected.to contain_exec('ceph-osd-check-udev-/srv/data').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
# Before Infernalis the udev rules race causing the activation to fail so we
# disable them. More at: http://www.spinics.net/lists/ceph-devel/msg28436.html
mv -f /usr/lib/udev/rules.d/95-ceph-osd.rules /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && udevadm control --reload || true
",
       'onlyif'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
DISABLE_UDEV=$(ceph --version | awk 'match(\$3, /[0-9]+\\.[0-9]+/) {if (substr(\$3, RSTART, RLENGTH) <= 0.94) {print 1}}')
test -f /usr/lib/udev/rules.d/95-ceph-osd.rules && test \$DISABLE_UDEV -eq 1
",
       'logoutput' => true,
      ) }
      it { is_expected.to contain_exec('ceph-osd-check-fsid-mismatch-/srv/data').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test f39ace04-f967-4c3d-9fd2-32af2d2d2cd5 = $(ceph-disk list $(readlink -f /srv/data) | egrep -o '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}')
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
test -z $(ceph-disk list $(readlink -f /srv/data) | egrep -o '[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}')
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-prepare-/srv/data').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv/data)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
ceph-disk prepare --cluster testcluster --cluster-uuid f39ace04-f967-4c3d-9fd2-32af2d2d2cd5 $(readlink -f /srv/data) $(readlink -f /srv/journal)
udevadm settle
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv/data)
ceph-disk list | egrep \" *(${disk}1?|${disk}p1?) .*ceph data, (prepared|active)\" ||
{ test -f $disk/fsid && test -f $disk/ceph_fsid && test -f $disk/magic ;}
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-activate-/srv/data').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv/data)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
# activate happens via udev when using the entire device
if ! test -b \$disk && ! ( test -b \${disk}1 || test -b \${disk}p1 ); then
  ceph-disk activate $disk || true
fi
if test -f /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && ( test -b ${disk}1 || test -b ${disk}p1 ); then
  ceph-disk activate ${disk}1 || true
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | egrep \" *(\${disk}1?|\${disk}p1?) .*ceph data, active\" ||
ls -ld /var/lib/ceph/osd/testcluster-* | grep \" $(readlink -f /srv/data)\$\"
",
        'logoutput' => true
      ) }
    end

    describe "with NVMe param" do

      let :title do
        '/dev/nvme0n1'
      end

      it { is_expected.to contain_exec('ceph-osd-check-udev-/dev/nvme0n1').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
# Before Infernalis the udev rules race causing the activation to fail so we
# disable them. More at: http://www.spinics.net/lists/ceph-devel/msg28436.html
mv -f /usr/lib/udev/rules.d/95-ceph-osd.rules /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && udevadm control --reload || true
",
       'onlyif'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
DISABLE_UDEV=$(ceph --version | awk 'match(\$3, /[0-9]+\\.[0-9]+/) {if (substr(\$3, RSTART, RLENGTH) <= 0.94) {print 1}}')
test -f /usr/lib/udev/rules.d/95-ceph-osd.rules && test \$DISABLE_UDEV -eq 1
",
       'logoutput' => true,
      ) }
      it { is_expected.to contain_exec('ceph-osd-prepare-/dev/nvme0n1').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /dev/nvme0n1)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
ceph-disk prepare --cluster ceph  $(readlink -f /dev/nvme0n1) $(readlink -f '')
udevadm settle
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /dev/nvme0n1)
ceph-disk list | egrep \" *(${disk}1?|${disk}p1?) .*ceph data, (prepared|active)\" ||
{ test -f $disk/fsid && test -f $disk/ceph_fsid && test -f $disk/magic ;}
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-activate-/dev/nvme0n1').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /dev/nvme0n1)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
# activate happens via udev when using the entire device
if ! test -b \$disk && ! ( test -b \${disk}1 || test -b \${disk}p1 ); then
  ceph-disk activate $disk || true
fi
if test -f /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && ( test -b ${disk}1 || test -b ${disk}p1 ); then
  ceph-disk activate ${disk}1 || true
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | egrep \" *(\${disk}1?|\${disk}p1?) .*ceph data, active\" ||
ls -ld /var/lib/ceph/osd/ceph-* | grep \" $(readlink -f /dev/nvme0n1)\$\"
",
        'logoutput' => true
      ) }
    end

    describe "with cciss param" do

      let :title do
        '/dev/cciss/c0d0'
      end

      it { is_expected.to contain_exec('ceph-osd-check-udev-/dev/cciss/c0d0').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
# Before Infernalis the udev rules race causing the activation to fail so we
# disable them. More at: http://www.spinics.net/lists/ceph-devel/msg28436.html
mv -f /usr/lib/udev/rules.d/95-ceph-osd.rules /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && udevadm control --reload || true
",
       'onlyif'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
DISABLE_UDEV=$(ceph --version | awk 'match(\$3, /[0-9]+\\.[0-9]+/) {if (substr(\$3, RSTART, RLENGTH) <= 0.94) {print 1}}')
test -f /usr/lib/udev/rules.d/95-ceph-osd.rules && test \$DISABLE_UDEV -eq 1
",
       'logoutput' => true,
      ) }
      it { is_expected.to contain_exec('ceph-osd-prepare-/dev/cciss/c0d0').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /dev/cciss/c0d0)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
ceph-disk prepare --cluster ceph  $(readlink -f /dev/cciss/c0d0) $(readlink -f '')
udevadm settle
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /dev/cciss/c0d0)
ceph-disk list | egrep \" *(${disk}1?|${disk}p1?) .*ceph data, (prepared|active)\" ||
{ test -f $disk/fsid && test -f $disk/ceph_fsid && test -f $disk/magic ;}
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-activate-/dev/cciss/c0d0').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /dev/cciss/c0d0)
if ! test -b $disk ; then
    echo $disk | egrep -e '^/dev' -q -v
    mkdir -p $disk
    if getent passwd ceph >/dev/null 2>&1; then
        chown -h ceph:ceph $disk
    fi
fi
# activate happens via udev when using the entire device
if ! test -b \$disk && ! ( test -b \${disk}1 || test -b \${disk}p1 ); then
  ceph-disk activate $disk || true
fi
if test -f /usr/lib/udev/rules.d/95-ceph-osd.rules.disabled && ( test -b ${disk}1 || test -b ${disk}p1 ); then
  ceph-disk activate ${disk}1 || true
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-disk list | egrep \" *(\${disk}1?|\${disk}p1?) .*ceph data, active\" ||
ls -ld /var/lib/ceph/osd/ceph-* | grep \" $(readlink -f /dev/cciss/c0d0)\$\"
",
        'logoutput' => true
      ) }
    end

    describe "with ensure absent" do

      let :title do
        '/srv'
      end

      let :params do
        {
          :ensure => 'absent',
        }
      end

      it { is_expected.to contain_exec('remove-osd-/srv').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv)
if [ -z \"\$id\" ] ; then
  id=$(ceph-disk list | sed -nEe \"s:^ *${disk}1? .*(ceph data|mounted on).*osd\\.([0-9]+).*:\\2:p\")
fi
if [ -z \"\$id\" ] ; then
  id=$(ls -ld /var/lib/ceph/osd/ceph-* | sed -nEe \"s:.*/ceph-([0-9]+) *-> *${disk}\$:\\1:p\" || true)
fi
if [ \"\$id\" ] ; then
  stop ceph-osd cluster=ceph id=\$id || true
  service ceph stop osd.\$id || true
  systemctl stop ceph-osd@$id || true
  ceph --cluster ceph osd crush remove osd.\$id
  ceph --cluster ceph auth del osd.\$id
  ceph --cluster ceph osd rm \$id
  rm -fr /var/lib/ceph/osd/ceph-\$id/*
  umount /var/lib/ceph/osd/ceph-\$id || true
  rm -fr /var/lib/ceph/osd/ceph-\$id
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
disk=$(readlink -f /srv)
if [ -z \"\$id\" ] ; then
  id=$(ceph-disk list | sed -nEe \"s:^ *${disk}1? .*(ceph data|mounted on).*osd\\.([0-9]+).*:\\2:p\")
fi
if [ -z \"\$id\" ] ; then
  id=$(ls -ld /var/lib/ceph/osd/ceph-* | sed -nEe \"s:.*/ceph-([0-9]+) *-> *${disk}\$:\\1:p\" || true)
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

    describe "with ensure set to bad value" do

      let :title do
        '/srv'
      end

      let :params do
        {
          :ensure => 'badvalue',
        }
      end

      it { is_expected.to raise_error(Puppet::Error, /Ensure on OSD must be either present or absent/) }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end

      it_behaves_like 'ceph osd'
    end
  end
end

# Local Variables:
# compile-command: "cd ../.. ;
#    bundle install ;
#    bundle exec rake spec
# "
# End:
