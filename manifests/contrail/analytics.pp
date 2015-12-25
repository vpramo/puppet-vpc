###
## Class: rjil::contrail
## Class for deploying contrail analytics
###
class rjil::contrail::analytics (
  $api_virtual_ip   = join(values(service_discover_consul('pre-haproxy')),""),
  $discovery_virtual_ip = join(values(service_discover_consul('pre-haproxy')),""),
) {

  anchor{'contrail_dep_apps':}
  Service<| title == 'cassandra' |>       ~> Anchor['contrail_dep_apps']

  Anchor['contrail_dep_apps'] -> Service['contrail-analytics-api']
  Anchor['contrail_dep_apps'] -> Service['contrail-collector']
  Anchor['contrail_dep_apps'] -> Service['contrail-query-engine']

  class{'::contrail':
    enable_analytics     => true,
    enable_config        => false,
    enable_control       => false,
    enable_webui         => false,
    enable_ifmap         => false,
    enable_dns           => false,
    api_virtual_ip       => $api_virtual_ip,
    discovery_virtual_ip => $discovery_virtual_ip,
  }

}


