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

# Installs and configures OSDs (ceph object storage daemons)
### == Parameters
# [*osd_data*] The OSDs data location.
#   Optional. Defaults provided by ceph is '/var/lib/ceph/osd/$cluster-$id'.
#
# [*osd_journal*] The path to the OSD’s journal.
#   Optional. Absolute path. Defaults to '/var/lib/ceph/osd/$cluster-$id/journal'
#
# [*osd_journal_size*] The size of the journal in megabytes.
#   Optional. Default provided by Ceph.
#
# [*keyring*] The location of the keyring used by OSDs
#   Optional. Defaults to '/var/lib/ceph/osd/$cluster-$id/keyring'
#
# [*filestore_flusher*] Allows to enable the filestore flusher.
#   Optional. Default provided by Ceph.
#
# [*osd_mkfs_type*] Type of the OSD filesystem.
#   Optional. Defaults to 'xfs'.
#
# [*osd_mkfs_options*] The options used to format the OSD fs.
#   Optional. Defaults to '-f' for XFS.
#
# [*osd_mount_options*] The options used to mount the OSD fs.
#   Optional. Defaults to 'rw,noatime,inode64,nobootwait' for XFS.
#

class ceph::osd (
  $osd_data           = '/var/lib/ceph/osd/$cluster-$id',
  $osd_journal        = '/var/lib/ceph/osd/$cluster-$id/journal',
  $osd_journal_size   = undef,
  $keyring            = '/var/lib/ceph/osd/$cluster-$id/keyring',
  $filestore_flusher  = undef,
  $osd_mkfs_type      = 'xfs',
  $osd_mkfs_options   = '-f',
  $osd_mount_options  = 'rw,noatime,inode64,nobootwait',
) {

  # [osd]
  ceph_config {
    'osd/osd_data':           value => $osd_data;
    'osd/osd_journal':        value => $osd_journal;
    'osd/osd_journal_size':   value => $osd_journal_size;
    'osd/keyring':            value => $keyring;
    'osd/filestore_flusher':  value => $filestore_flusher;
    'osd/osd_mkfs_type':      value => $osd_mkfs_type;
    'osd/osd_mkfs_options':   value => $osd_mkfs_options;
    'osd/osd_mount_options':  value => $osd_mount_options;
  }
}