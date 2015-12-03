require 'spec_helper'

describe 'rjil::apparmor' do

  it 'should install package and start service' do
    should contain_package('apparmor').with_ensure('present')

    should contain_service('apparmor').with_ensure('running')
  end

end
