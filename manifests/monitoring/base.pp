## Monitor base class for all types of nodes and common checks
class rjil::monitoring::base {

  $monitors= ['monitor_validation.sh','monitor_updates.sh']
  class rjil::monitoring { $monitors:}

}


