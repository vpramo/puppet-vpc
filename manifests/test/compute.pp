#
# Class: rjil::test::compute
#

class rjil::test::compute {

  $scripts = ['nova-compute.sh']

  rjil::test { $scripts: }
}
