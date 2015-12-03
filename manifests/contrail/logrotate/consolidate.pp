class rjil::contrail::logrotate::consolidate {
  file { '/usr/local/bin/contrail-consolidate-logs.sh':
    source => 'puppet:///modules/rjil/contrail-consolidate-logs.sh',
    mode   => '0755',
    owner  => 'root',
    group  => 'root'
  }
  cron { 'contrail-consolidate-logs':
    command => 'run-one /usr/local/bin/contrail-consolidate-logs.sh 2>&1 | logger',
    user    => 'root',
    require => Package['run-one'],
  }
}