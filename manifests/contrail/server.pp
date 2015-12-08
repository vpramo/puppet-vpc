###
## Class: rjil::contrail
###
class rjil::contrail::server (
  $enable_analytics = true,
  $enable_dns       = false,
  $vm_domain        = undef,
  $dns_port         = '10000',
  $api_virtual_ip   = service_disover_consul('pre-haproxy')['haproxy1'],
  $discovery_virtual_ip = service_disover_consul('pre-haproxy')['haproxy1'],
  $control_ip_list  = sort(values(service_discover_consul('pre-contrail'))),
  $zk_ip_list        = sort(values(service_discover_consul('zookeeper'))),
  $cassandra_ip_list = sort(values(service_discover_consul('cassandra'))),
  $min_members       = '3',
) {

  ##
  # Added tests
  ##
  $contrail_tests = ['ifmap.sh','contrail-api.sh',
                      'contrail-control.sh','contrail-discovery.sh',
                      'contrail-schema.sh',
                      'contrail-webui-webserver.sh','contrail-webui-jobserver.sh']
  rjil::test {$contrail_tests:}

  if $enable_analytics {
    rjil::test {'contrail-analytics.sh':}
  }

  if size($zk_ip_list) < $min_members or size($cassandra_ip_list) < $min_members {
    $fail = true
  } else {
    $fail = false
  }

  runtime_fail { 'contrail_data_not_ready':
    fail    => $fail,
    message => "Waiting for ${min_members} zk and cassandra for contrail",
    before  => Anchor['contrail_dep_apps'],
  }


  if size($control_ip_list) < $min_members or ! $api_virtual_ip or ! $discovery_virtual_ip {
     $contrail_fail= true
  } else {
     $contrail_fail= false
  }

  runtime_fail { 'contrail_ready':
    fail    => $contrail_fail,
    message => "Waiting for ${min_members} contrail control or haproxy endpoint is not ready",
    before  => Class['::contrail'],
  }


  anchor{'contrail_dep_apps':}
  Service<| title == 'zookeeper' |>       ~> Anchor['contrail_dep_apps']
  Service<| title == 'cassandra' |>       ~> Anchor['contrail_dep_apps']
  Service<| title == 'rabbitmq-server' |> ~> Anchor['contrail_dep_apps']

  Anchor['contrail_dep_apps'] -> Service['contrail-api']
  Anchor['contrail_dep_apps'] -> Service['contrail-schema']
  Anchor['contrail_dep_apps'] -> Service['contrail-discovery']
  #Anchor['contrail_dep_apps'] -> Service['contrail-dns']
  Anchor['contrail_dep_apps'] -> Service['contrail-control']
  Anchor['contrail_dep_apps'] -> Service['ifmap-server']
  
  if $enable_dns and $vm_domain {
    include dnsmasq
    dnsmasq::conf { 'contrail':
      ensure  => present,
      content => "server=/${vm_domain}/127.0.0.1#${dns_port}",
    }
    rjil::test {'contrail-dns.sh':}
  }


  $contrail_logs = ['contrail-api-daily',
                    'contrail-discovery-daily',
                    'contrail-schema-daily',
                    'contrail-svc-monitor-daily',
                    'contrail-api-0-zk-daily',
                    'contrail-collector-daily'
  ]

  rjil::jiocloud::logrotate { $contrail_logs:
    logdir => '/var/log/contrail'
  }

  # Add a check that always succeeds that we can use to know
  # when we have enough members ready to configure a cluster.
  rjil::jiocloud::consul::service { 'pre-contrail':
    check_command => '/bin/true',
    tags => ['real', 'contrail']
  }

  class {'::contrail':
    api_virtual_ip       => $api_virtual_ip,
    discovery_virtual_ip => $discovery_virtual_ip,
    control_ip_list      => $control_ip_list,
    zk_ip_list           => $zk_ip_list,
    cassandra_ip_list    => $cassandra_ip_list
  }
  
  ##
  # The logs which support higher filesize need either a sighup or
  # a copytruncate to rotate properly (else the process will keep writing to
  # older logfile. Using copytruncate to minimize any potential issue w/ sighup
  ##

  $contrail_logs_copytruncate = ['contrail-control',
                                'contrail-dns',
                                'contrail-ifmap-server',
  ]
  
  rjil::jiocloud::logrotate { $contrail_logs_copytruncate:
    logdir       => '/var/log/contrail',
    copytruncate => true,
  }
  
  include rjil::contrail::logrotate::consolidate

  ##
  # Deleting the default config logrotates which conflict with our changes
  # The default configs have multiple logfiles in a single config which
  # conflicts with our daily files setup
  ##
  $contrail_logrotate_delete = ['contrail-config',
                                'contrail-config-openstack',
                                'contrail-analytics',
                                'ifmap-server',
                                ]
  rjil::jiocloud::logrotate { $contrail_logrotate_delete:
    ensure => absent
  }

  rjil::test::check { 'contrail-api':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 9100,
  }

  rjil::jiocloud::consul::service { 'contrail-api':
    port          => 9100,
    tags          => ['real', 'contrail','api'],
  }

  rjil::test::check { 'contrail-discovery':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 9110,
  }

  rjil::jiocloud::consul::service { 'contrail-discovery':
    port          => 9110,
    tags          => ['real', 'contrail','discovery'],
  }

  rjil::test::check { 'contrail-control':
    type    => 'tcp',
    address => '127.0.0.1',
    port    => 5269,
  }

  rjil::jiocloud::consul::service { 'contrail-control':
    port          => 5269,
    tags          => ['real', 'contrail','control'],
  }


}
