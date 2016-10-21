#
#   Copyright (C) 2016 University of Michigan, funded by the NSF OSiRIS Project
#
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
# Author: Ben Meekhof <bmeekhof@umich.edu>
#
# == Class: ceph::clusters
#
# Class wrapper for the benefit of scenario_node_terminus
#
# === Parameters:
#
# [*args*] A Ceph clusters config hash
#   Optional.
#
# [*defaults*] A clusters config hash
#   Optional. Defaults to a empty hash.
#
class ceph::clusters($args = {}, $defaults = {}) {
  create_resources(ceph::cluster, $args, $defaults)
}