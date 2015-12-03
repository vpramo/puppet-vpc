#
# Class: rjil::redis
#  This class to manage contrail redis dependency
#
#

class rjil::redis {

  rjil::test { 'check_redis.sh': }

  include ::redis

}
