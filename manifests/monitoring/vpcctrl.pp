class rjil::monitoring::vpcctrl {

  ## Add the name of the scripts you have added in files/monitor_scripts/
  ## Example: $monitors = ['monitor_xmpp.sh','monitor_cassandra.sh']
  $monitors=['contrail_control_introspect.sh','contrail_config_introspect.sh']
  rjil::monitoring { $monitors:}

}
