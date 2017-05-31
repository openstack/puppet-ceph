#
#  Copyright (C) 2016 Keith Schincke
#  Copyright (C) 2016 OSiRIS Project, funded by the NSF
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
# Author: Keith Schincke <keith.schincke@gmail.com.>
# Author: Ben Meekhof <bmeekhof@umich.edu>
#
# Configures a ceph radosgw using civetweb.
#
# == Define: ceph::rgw::civetweb
#
# [*rgw_frontends*] Arguments to the rgw frontend
#   Optional. Default is undef. Example: "civetweb port=7480"
#   If defined over-rides all other individual params (for custom definition not supported by class params)

# [*client_id*] Client id used in config file [client.radosgw.clientid]
#   Optional. Default is resource name

# [*ssl_cert*] Path to ssl key and cert (concat into one file)
#   Optional. Default is undef. Port must be set to 443s to be relevant

# [*ssl_ca_file*] Path to file containing trusted ca certs
#   Optional. Default is undef.  

# [*port*] Port to listen on
#   Optional. Default is 80.  443s for SSL.
#

define ceph::rgw::civetweb (
  $rgw_frontends = undef,
  $ensure        = present,
  $client_id     = "${name}",
  $ssl_cert      = undef,
  $ssl_ca_file   = undef,
  $cluster       = 'ceph',
  $num_threads   = undef,
  $port          = '80'
) {

	if ! $rgw_frontends {
		if $ssl_cert { $certarg = "ssl_certificate=${ssl_cert}" }
    # civetweb docs say this is valid but ceph won't have it in the frontend args
		#if $ssl_ca_file { $carg = "ssl_ca_file=${ssl_ca_file}" }
    if $num_threads { $threadarg = "num_threads=${num_threads}" }

		$frontends = "civetweb port=${port} ${threadarg} ${certarg} ${carg}"
	} else {
		$frontends = $rgw_frontends
	}

    ceph_config {
      "${cluster}/client.${client_id}/rgw_frontends": value => $frontends, ensure => $ensure;
    }

}
