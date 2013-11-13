#   Copyright (C) iWeb Technologies Inc.
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
# Author: David Moreau Simard <dmsimard@iweb.com>

require 'spec_helper'

describe 'ceph::osd' do

  describe 'Debian Family' do
    let :facts do
      {
        :osfamily => 'Debian',
      }
    end

    describe "with default params" do

      it { should contain_ceph_config('osd/osd_data').with_value('/var/lib/ceph/osd/$cluster-$id') }
      it { should contain_ceph_config('osd/osd_journal').with_value('/var/lib/ceph/osd/$cluster-$id/journal') }
      it { should_not contain_ceph_config('osd/osd_journal_size').with_value('2048') }
      it { should contain_ceph_config('osd/keyring').with_value('/var/lib/ceph/osd/$cluster-$id/keyring') }
      it { should_not contain_ceph_config('osd/filestore_flusher').with_value('true') }
      it { should contain_ceph_config('osd/osd_mkfs_type').with_value('xfs') }
      it { should contain_ceph_config('osd/osd_mkfs_options').with_value('-f') }
      it { should contain_ceph_config('osd/osd_mount_options').with_value('rw,noatime,inode64,nobootwait') }

    end

    describe "with custom params" do
      let :params do
        {
          :osd_data           => '/usr/local/ceph/var/lib/osd/_cluster-_id',
          :osd_journal        => '/usr/local/ceph/var/lib/osd/_cluster-_id/journal',
          :osd_journal_size   => '2048',
          :keyring            => '/usr/local/ceph/var/lib/osd/_cluster-_id/keyring',
          :filestore_flusher  => 'true',
          :osd_mkfs_type      => 'ext4',
          :osd_mkfs_options   => '-V',
          :osd_mount_options  => 'defaults',
        }
      end

      it { should contain_ceph_config('osd/osd_data').with_value('/usr/local/ceph/var/lib/osd/_cluster-_id') }
      it { should contain_ceph_config('osd/osd_journal').with_value('/usr/local/ceph/var/lib/osd/_cluster-_id/journal') }
      it { should contain_ceph_config('osd/osd_journal_size').with_value('2048') }
      it { should contain_ceph_config('osd/keyring').with_value('/usr/local/ceph/var/lib/osd/_cluster-_id/keyring') }
      it { should contain_ceph_config('osd/filestore_flusher').with_value('true') }
      it { should contain_ceph_config('osd/osd_mkfs_type').with_value('ext4') }
      it { should contain_ceph_config('osd/osd_mkfs_options').with_value('-V') }
      it { should contain_ceph_config('osd/osd_mount_options').with_value('defaults') }

    end
  end
end