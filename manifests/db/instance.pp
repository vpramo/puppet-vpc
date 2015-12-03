## This is to create databases, users, and grants
define rjil::db::instance (
  $pass,
  $db   = $name,
  $user = $name,
  $grant = ['ALL'],
  $ensure = 'present',
  $charset = 'utf8',
  $table = "${name}.*",
) {
  ## Create databases
  mysql_database { $db:
    ensure   => $ensure,
    charset  => $charset,
    provider => 'mysql',
    require  => [ Class['mysql::server'] ],
    before   => Mysql_user["${user}@%"],
  }

  ## Create users
  $user_resource = {
    ensure        => $ensure,
    password_hash => mysql_password($pass),
    provider      => 'mysql',
    require       => Class['mysql::server'],
  }
  ensure_resource('mysql_user', "${user}@%", $user_resource)

  ## Create grants
  if $ensure == 'present' {
    mysql_grant { "${user}@%/${table}":
      privileges => $grant,
      provider   => 'mysql',
      user       => "${user}@%",
      table      => $table,
      require    => [ Mysql_user["${user}@%"], Class['mysql::server'] ],
    }
  }

}

