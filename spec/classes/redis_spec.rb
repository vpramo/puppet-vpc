require 'spec_helper'
require 'hiera-puppet-helper'

describe 'rjil::redis' do

  let :facts do
    {
      :operatingsystem => 'Ubuntu',
      :osfamily        => 'Debian',
      :lsbdistid       => 'ubuntu',
    }
  end

  context 'with defaults' do
    it do
      should contain_file('/usr/lib/jiocloud/tests/check_redis.sh')
      should contain_class('redis')
    end
  end

end
