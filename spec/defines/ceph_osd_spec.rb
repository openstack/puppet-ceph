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
  shared_examples 'ceph osd' do
    describe "with default params" do
      let :title do
        'vg_test/lv_test'
      end

      it { should contain_exec('ceph-osd-prepare-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo vg_test/lv_test|cut -c 1) = '/' ]; then
    disk=vg_test/lv_test
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/vg_test/lv_test
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare  --cluster ceph  --data vg_test/lv_test 
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list vg_test/lv_test
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo vg_test/lv_test|cut -c 1) = '/' ]; then
    disk=vg_test/lv_test
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/vg_test/lv_test
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list vg_test/lv_test | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

    describe "with bluestore params" do
      let :title do
        'vg_test/lv_test'
      end

      let :params do
        {
          :cluster       => 'testcluster',
          :journal       => '/srv/journal',
          :fsid          => 'f39ace04-f967-4c3d-9fd2-32af2d2d2cd5',
          :store_type    => 'bluestore',
          :bluestore_wal => 'vg_test/lv_wal',
          :bluestore_db  => 'vg_test/lv_db',
        }
      end

      it { should contain_exec('ceph-osd-check-fsid-mismatch-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
exit 1
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z $(ceph-volume lvm list vg_test/lv_test |grep 'cluster fsid' | awk -F'fsid' '{print \$2}'|tr -d  ' ') ]; then
    exit 0
fi
test f39ace04-f967-4c3d-9fd2-32af2d2d2cd5 = $(ceph-volume lvm list vg_test/lv_test |grep 'cluster fsid' | awk -F'fsid' '{print \$2}'|tr -d  ' ')
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-prepare-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo vg_test/lv_test|cut -c 1) = '/' ]; then
    disk=vg_test/lv_test
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/vg_test/lv_test
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare --bluestore --cluster testcluster --cluster-fsid f39ace04-f967-4c3d-9fd2-32af2d2d2cd5 --data vg_test/lv_test --block.wal vg_test/lv_wal --block.db vg_test/lv_db
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list vg_test/lv_test
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo vg_test/lv_test|cut -c 1) = '/' ]; then
    disk=vg_test/lv_test
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/vg_test/lv_test
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list vg_test/lv_test | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

     describe "with dmcrypt enabled" do

       let :title do
        '/dev/sdc'
      end

       let :params do
        {
          :dmcrypt => true,
        }
      end

      it { is_expected.to contain_exec('ceph-osd-prepare-/dev/sdc').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo /dev/sdc|cut -c 1) = '/' ]; then
    disk=/dev/sdc
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/sdc
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare  --cluster ceph --dmcrypt --dmcrypt-key-dir '/etc/ceph/dmcrypt-keys'  --data /dev/sdc 
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list /dev/sdc
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-activate-/dev/sdc').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo /dev/sdc|cut -c 1) = '/' ]; then
    disk=/dev/sdc
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/sdc
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list /dev/sdc | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list /dev/sdc | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list /dev/sdc | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

     describe "with dmcrypt custom keydir" do

       let :title do
        '/dev/sdc'
      end

       let :params do
        {
          :dmcrypt         => true,
          :dmcrypt_key_dir => '/srv/ceph/keys',
        }
      end

      it { is_expected.to contain_exec('ceph-osd-prepare-/dev/sdc').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo /dev/sdc|cut -c 1) = '/' ]; then
    disk=/dev/sdc
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/sdc
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare  --cluster ceph --dmcrypt --dmcrypt-key-dir '/srv/ceph/keys'  --data /dev/sdc 
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list /dev/sdc
",
        'logoutput' => true
      ) }
      it { is_expected.to contain_exec('ceph-osd-activate-/dev/sdc').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo /dev/sdc|cut -c 1) = '/' ]; then
    disk=/dev/sdc
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/sdc
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list /dev/sdc | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list /dev/sdc | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list /dev/sdc | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

    describe "with custom params" do
      let :title do
        'vg_test/lv_test'
      end

      let :params do
        {
          :cluster    => 'testcluster',
          :journal    => 'vg_test/lv_journal',
          :fsid       => 'f39ace04-f967-4c3d-9fd2-32af2d2d2cd5',
          :store_type => 'filestore'
        }
      end

      it { should contain_exec('ceph-osd-check-fsid-mismatch-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
exit 1
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ -z $(ceph-volume lvm list vg_test/lv_test |grep 'cluster fsid' | awk -F'fsid' '{print \$2}'|tr -d  ' ') ]; then
    exit 0
fi
test f39ace04-f967-4c3d-9fd2-32af2d2d2cd5 = $(ceph-volume lvm list vg_test/lv_test |grep 'cluster fsid' | awk -F'fsid' '{print \$2}'|tr -d  ' ')
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-prepare-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo vg_test/lv_test|cut -c 1) = '/' ]; then
    disk=vg_test/lv_test
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/vg_test/lv_test
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare --filestore --cluster testcluster --cluster-fsid f39ace04-f967-4c3d-9fd2-32af2d2d2cd5 --data vg_test/lv_test --journal vg_test/lv_journal
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list vg_test/lv_test
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo vg_test/lv_test|cut -c 1) = '/' ]; then
    disk=vg_test/lv_test
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev/vg_test/lv_test
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list vg_test/lv_test | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

    describe "with NVMe param" do

      let :title do
        '/dev/nvme0n1'
      end

      it { should contain_exec('ceph-osd-prepare-/dev/nvme0n1').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo /dev/nvme0n1|cut -c 1) = '/' ]; then
    disk=/dev/nvme0n1
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/nvme0n1
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare  --cluster ceph  --data /dev/nvme0n1 
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list /dev/nvme0n1
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-/dev/nvme0n1').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo /dev/nvme0n1|cut -c 1) = '/' ]; then
    disk=/dev/nvme0n1
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/nvme0n1
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list /dev/nvme0n1 | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list /dev/nvme0n1 | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list /dev/nvme0n1 | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

    describe "with cciss param" do

      let :title do
        '/dev/cciss/c0d0'
      end

      it { should contain_exec('ceph-osd-prepare-/dev/cciss/c0d0').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex

if [ $(echo /dev/cciss/c0d0|cut -c 1) = '/' ]; then
    disk=/dev/cciss/c0d0
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/cciss/c0d0
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
ceph-volume lvm prepare  --cluster ceph  --data /dev/cciss/c0d0 
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
ceph-volume lvm list /dev/cciss/c0d0
",
        'logoutput' => true
      ) }
      it { should contain_exec('ceph-osd-activate-/dev/cciss/c0d0').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
if [ $(echo /dev/cciss/c0d0|cut -c 1) = '/' ]; then
    disk=/dev/cciss/c0d0
else
    # If data is vg/lv, block device is /dev/vg/lv
    disk=/dev//dev/cciss/c0d0
fi
if ! test -b \$disk ; then
    # Since nautilus, only block devices or lvm logical volumes can be used for OSDs
    exit 1
fi
id=$(ceph-volume lvm list /dev/cciss/c0d0 | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
fsid=$(ceph-volume lvm list /dev/cciss/c0d0 | grep 'osd fsid'|awk -F 'osd fsid' '{print \$2}'|tr -d ' ')
ceph-volume lvm activate \$id \$fsid
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list /dev/cciss/c0d0 | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
ps -fCceph-osd|grep \"\\--id \$id \"
",
        'logoutput' => true
      ) }
    end

    describe "with ensure absent" do

      let :title do
        'vg_test/lv_test'
      end

      let :params do
        {
          :ensure => 'absent',
        }
      end

      it { should contain_exec('remove-osd-vg_test/lv_test').with(
        'command'   => "/bin/true # comment to satisfy puppet syntax requirements
set -ex
id=$(ceph-volume lvm list vg_test/lv_test | grep 'osd id'|awk -F 'osd id' '{print \$2}'|tr -d ' ')
if [ \"\$id\" ] ; then
  ceph --cluster ceph osd out osd.\$id
  stop ceph-osd cluster=ceph id=\$id || true
  service ceph stop osd.\$id || true
  systemctl stop ceph-osd@\$id || true
  ceph --cluster ceph osd crush remove osd.\$id
  ceph --cluster ceph auth del osd.\$id
  ceph --cluster ceph osd rm \$id
  rm -fr /var/lib/ceph/osd/ceph-\$id/*
  umount /var/lib/ceph/osd/ceph-\$id || true
  rm -fr /var/lib/ceph/osd/ceph-\$id
  ceph-volume lvm zap vg_test/lv_test
fi
",
        'unless'    => "/bin/true # comment to satisfy puppet syntax requirements
set -x
ceph-volume lvm list vg_test/lv_test
if [ \$? -eq 0 ]; then
    exit 1
else
    exit 0
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

      it { should raise_error(Puppet::Error, /Ensure on OSD must be either present or absent/) }
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
