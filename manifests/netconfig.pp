#
# class rjil::netconfig
#   Configure /etc/network/interfaces to source extra interface configurations
#   from /etc/network/interfaces.d, and loopback interface configuration.
#   It also create execs network_down and network_up which would be called from
#   rjil::network::interface
#

class rjil::netconfig {

  file {'/etc/network/interfaces':
    ensure => file,
    source => 'puppet:///modules/rjil/etc_network_interfaces',
  }

  exec { 'network_down':
    command     => '/sbin/ifdown -a',
    refreshonly => true,
  }

  exec { 'network_up':
    command     => '/sbin/ifup -a',
    refreshonly => true,
  }
}
