#
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
# Author: David Gurtner <aldavud@crimson.ch>
#
# == Class: ceph::osds
#
# Class wrapper for the benefit of scenario_node_terminus
#
# === Parameters:
#
# [*args*] A Ceph osds config hash
#   Optional.
#
# [*defaults*] A config hash
#   Optional. Defaults to a empty hash
#
# [*pid_max*] Value for pid_max. Defaults to undef. Optional.
#   For OSD nodes it is recommended that you raise pid_max above the
#   default value because you may hit the system max during
#   recovery. The recommended value is the absolute max for pid_max: 4194303
#   http://docs.ceph.com/docs/luminous/rados/troubleshooting/troubleshooting-osd/
#
class ceph::osds(
  $args = {},
  $defaults = {},
  $pid_max = $::ceph::profile::params::pid_max,
)
{
  create_resources(ceph::osd, $args, $defaults)

  if $pid_max {
    $sysctl_settings = {
      'kernel.pid_max' => { value => $pid_max },
    }
    ensure_resources(sysctl::value,$sysctl_settings)
  }
}
