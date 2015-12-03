define rjil::jiocloud::aptrepo::publish(
  $basedir
) {
  file { "/srv/www/apt/${name}":
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }
  file { "/srv/www/apt/${name}/dists":
    ensure => 'link',
    target => "${basedir}/${name}/dists",
  }
  file { "/srv/www/apt/${name}/pool":
    ensure => 'link',
    target => "${basedir}/${name}/pool",
  }
}
