#
# Copyright (C) 2017, VEXXHOST, Inc.
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
# Author: Mohammed Naser <mnaser@vexxhost.com>
#
# == Class: ceph::profile::mgr
#
# Profile for a Ceph mgr
#
class ceph::profile::mgr {
  require ::ceph::profile::base

  ceph::mgr { $::hostname:
    authentication_type => $ceph::profile::params::authentication_type,
    key                 => $ceph::profile::params::mgr_key,
    inject_key          => true,
  }
}
