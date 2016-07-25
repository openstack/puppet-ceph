define ceph::restapi (
  $cluster             = 'ceph',
  $keyring             = undef,
  $public_addr         = undef,
  $log_file            = undef,
  $restapi_base_url    = undef,
  $restapi_log_level   = undef,
) {

    # [client.rest]
    ceph_config {
      "$cluster/client.rest/keyring":           value => $keyring;
      "$cluster/client.rest/public addr":       value => $public_addr;
      "$cluster/client.rest/log file":          value => $log_file;
      "$cluster/client.rest/restapi base url":  value => $restapi_base_url;
      "$cluster/client.rest/restapi log level": value => $restapi_log_level;

   }

 }