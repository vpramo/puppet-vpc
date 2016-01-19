class rjil::monitoring::vpccfg {

  ## Add the name of the scripts you have added in files/monitor_scripts/
  ## Example: $monitors = ['monitor_xmpp.sh','monitor_cassandra.sh']
  $monitors=[]
  rjil::monitoring { $monitors:}

}


