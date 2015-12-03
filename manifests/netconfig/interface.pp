#
# Define - rjil::netconfig::interface
#   Configure network interfaces
#
# == parameters
#
# [*interface*]
#   interface name
#
# [*onboot*]
#   whether to enable on boot or not
#
# [*method*]
#   Methods - static, dhcp, manual
#
# [*macaddress*]
#   Mac address
#
# [*ipaddress*]
#   IP Address
#
# [*netmask*]
#   Subnet mask
#
# [*network*]
#   Network
#
# [*gateway*]
#   Gateway
#
# [*nameservers*]
#   Array of all name servers
#
# [*searchdomains*]
#   An array with all search domains.
#
# [*options*]
#   A hash to configure any extra options like pre-up, up, down, pre-down.
#   Multiple options for specific state can be specified as an array. e.g
#   options => {
#                 up   => ['do this','do this too'],
#                 down => 'do this only'
#               }
#
# [*refresh_network*]
# Whether to restart network after the interface file changes or not.
#

define rjil::netconfig::interface (
  $interface       = $name,
  $onboot          = true,
  $family          = 'inet',
  $method          = 'dhcp',
  $macaddress      = undef,
  $ipaddress       = undef,
  $netmask         = undef,
  $network         = undef,
  $broadcast       = undef,
  $gateway         = undef,
  $nameservers     = [],
  $searchdomains   = [],
  $options         = {},
  $refresh_network = true,
) {

  include rjil::netconfig

  if ($method == 'static') and (! $ipaddress) {
    fail('ipaddress is required for static method')
  }

  if ($method == 'static') and (! $netmask) {
    fail('netmask is required for static method')
  }

  if $refresh_network {
    file {"/etc/network/interfaces.d/${interface}.cfg.staging":
      ensure  => present,
      content => template('rjil/etc_network_interfaces_d_file.erb'),
      notify  => Exec['network_down']
    }

    file {"/etc/network/interfaces.d/${interface}.cfg":
      ensure  => file,
      source  => "/etc/network/interfaces.d/${interface}.cfg.staging",
      require => Exec['network_down'],
      notify  => Exec['network_up'],
    }

  } else {
    file {"/etc/network/interfaces.d/${interface}.cfg":
      ensure  => file,
      content => template('rjil/etc_network_interfaces_d_file.erb'),
    }
  }

}
