#
#  Copyright (C) 2014 Nine Internet Solutions
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
# == Class: ceph::keys
#
# Class wrapper for the benefit of scenario_node_terminus
#
# === Parameters:
#
# [*args*] A Ceph keys config hash
#   Optional. The secret of each key is always passed on to ceph::key as a
#   Sensitive value so that it is redacted in the catalog, reports and logs.
#
# [*defaults*] A keys config hash
#   Optional. Defaults to a empty hash.
#
class ceph::keys (
  Hash $args     = {},
  Hash $defaults = {},
) {
  # Wrap the secret of each key in Sensitive so that it is redacted in the
  # catalog, reports and logs. Sensitive() returns the value as-is when it is
  # already a Sensitive.
  $args_real = Hash($args.map |$key_name, $key_args| {
    if $key_args =~ Hash and 'secret' in $key_args {
      [$key_name, $key_args + { 'secret' => Sensitive($key_args['secret']) }]
    } else {
      [$key_name, $key_args]
    }
  })

  create_resources(ceph::key, $args_real, $defaults)
}
