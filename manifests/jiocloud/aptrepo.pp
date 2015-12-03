#
# sets up apt repos
#
class rjil::jiocloud::aptrepo(
  $basedir = '/var/lib/reprepro',
  $repositories = {},
  $distributions = {},
  $vhost = 'apt.internal.jiocloud.com'
) {

  include ::reprepro

  file { ['/srv', '/srv/www', '/srv/www/apt']:
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

  create_resources(::rjil::jiocloud::aptrepo::publish, $repositories, { basedir => $basedir })

  include ::apache
  apache::vhost { $vhost:
    port => '80',
    docroot => '/srv/www/apt'
  }

  create_resources(::reprepro::repository, $repositories, { basedir => $basedir })
  create_resources(::reprepro::distribution,
    $distributions,
    { basedir       => $basedir,
      architectures => 'amd64 i386',
      components    => 'main',
      not_automatic => 'No' })
}
