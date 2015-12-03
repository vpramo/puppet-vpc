##
#  Class rjil::apparmor
#  Manage apparmor
#
class rjil::apparmor {
  package {'apparmor':
    ensure => present,
  }

  service {'apparmor':
    ensure => 'running',
  }
}
