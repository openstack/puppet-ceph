#
#   Copyright (C) 2013 Cloudwatt <libre.licensing@cloudwatt.com>
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
#
# == Class: ceph::conf
#
# Class wrapper for the benefit of scenario_node_terminus
#
# === Parameters:
#
# [*args*] A Ceph config hash.
#   Optional.
#
# [*defaults*] A config hash
#   Optional. Defaults to a empty hash
#
class ceph::conf($args = {}, $defaults = {}) {
  ensure_resources(ceph_config, $args, $defaults)
}
