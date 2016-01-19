define rjil::monitoring {

  file { "/usr/lib/check_mk_agent/local/${name}":
    source  => "puppet:///modules/rjil/monitor_scripts/${name}",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['check-mk-agent']
  }

}
