require 'spec_helper'

describe 'rjil::jiocloud::jenkins::master' do

  let :facts do
    {
      'osfamily' => 'Debian',
      'lsbdistcodename' => 'natty',
      'lsbdistcodename' => 'precise',
      'lsbdistid'       => 'ubuntu',
    }
  end

  it 'should configure defaults' do
    should contain_class('jenkins')
    should contain_class('rjil::jiocloud::jenkins')
    {
      "ant"                       => "1.2",
      "credentials"               => "1.18",
      "cvs"                       => "2.12",
      "external-monitor-job"      => "1.2",
      "git-client"                => "1.11.0",
      "git"                       => "2.2.7",
      "greenballs"                => "1.14",
      "javadoc"                   => "1.2",
      "junit"                     => "1.1",
      "ldap"                      => "1.11",
      "mailer"                    => "1.11",
      "mapdb-api"                 => "1.0.1.0",
      "matrix-auth"               => "1.2",
      "matrix-project"            => "1.4",
      "maven-plugin"              => "2.7",
      "antisamy-markup-formatter" => "1.2",
      "pam-auth"                  => "1.2",
      "parameterized-trigger"     => "2.25",
      "scm-api"                   => "0.2",
      "ssh-credentials"           => "1.10",
      "ssh-slaves"                => "1.8",
      "subversion"                => "2.4.4",
      "translation"               => "1.11"
    }.each do |k,v|
      should contain_jenkins__plugin(k).with_version(v)
    end
    should contain_file('/home/jenkins/.gitconfig')
  end

end
