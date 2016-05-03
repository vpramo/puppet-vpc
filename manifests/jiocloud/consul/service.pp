define rjil::jiocloud::consul::service(
  $port          = 0,
  $check_command = "/usr/lib/jiocloud/tests/service_checks/${name}.sh",
  $interval      = '10s',
  $ttl           = false,
  $tags          = [],
  $ip_address    = undef,
) {

  if $check_command {
    $check = {
      script => $check_command,
      interval => $interval
    }
  } elsif $ttl {
    $check = {
      ttl => $ttl,
    }
  } else {
    fail("Must specify either ttl or check_command")
  }
 
  if $ip_address {
    $service_hash = {
      service => {
        name  => $name,
        address => $ip_address,
        port  => $port + 0,
        tags  => $tags,
        check => $check,
      }
    }
  } else {
    $service_hash = {
      service => {
        name  => $name,
        port  => $port + 0,
        tags  => $tags,
        check => $check,
      }
  }
  }

  ensure_resource( 'file', '/etc/consul',
    {'ensure' => 'directory'}
  )

  file { "/etc/consul/$name.json":
    ensure => "present",
    content => template('rjil/consul.service.erb'),
  } ~> Exec <| title == 'reload-consul' |>
}
