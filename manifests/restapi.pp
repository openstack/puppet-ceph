#   Copyright (C) 2013, 2014 iWeb Technologies Inc.
# Copyright (C) 2016 OSiRIS Project, funded by the NSF
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
# Author: Charlie Miller <cdmiller@msu.edu>
#
# == Class: ceph::restapi
#
# Configures ceph-rest-api to run as daemon.
#
# === Parameters:
#
#
# [*cluster*] If cluster name is not 'ceph' define this appropriately
#
# [*keyring*] The keyring file holding the key for ‘clientname’
#
# [*public_addr*] ip:port to listen on (default 0.0.0.0:5000)
#
# [*log_file*] (usual Ceph default)
#
# [*restapi_base_url*] The base URL to answer requests on (default /api/v0.1)
#
# [*restapi_log_level*] critical, error, warning, info, debug (default warning)
#

define ceph::restapi (
  $cluster             = 'ceph',
  $keyring             = undef,
  $public_addr         = undef,
  $log_file            = undef,
  $restapi_base_url    = undef,
  $restapi_log_level   = undef,
) {

$service_name = "ceph-rest-api@${name}"
$unit = '/usr/lib/systemd/system/ceph-rest-api@.service'
 
    file       { "${unit}" :
        content        => file("ceph/restapi/ceph-rest-api@.service"),
        owner          => 'root',
        group          => 'root',
        mode           => '0644',
        notify         => Exec['daemon-reload'],
    }
    exec       {"daemon-reload":
        command        => '/bin/systemctl daemon-reload',
        refreshonly    => true
    }
    service    { "$service_name":
        require        => File["${unit}"],
        ensure         => 'running',
        enable         => 'true',
    }

    # [client.rest]
    ceph_config {
      "$cluster/client.rest/keyring":           value => $keyring;
      "$cluster/client.rest/public addr":       value => $public_addr;
      "$cluster/client.rest/log file":          value => $log_file;
      "$cluster/client.rest/restapi base url":  value => $restapi_base_url;
      "$cluster/client.rest/restapi log level": value => $restapi_log_level;
    }

    Ceph_config<||> ~> Service["${service_name}"]
    Package<| tag == 'ceph' |> ~> File['/usr/lib/systemd/system/ceph-rest-api@.service']
    File['/usr/lib/systemd/system/ceph-rest-api@.service']
    ~> Service["${service_name}"]
    Ceph::Pool<||> ~> Service["${service_name}"]

 }