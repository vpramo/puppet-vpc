#
# Class: rjil::jiocloud::dashboard
#

class rjil::jiocloud::dashboard($keystone_url,
                                $secret_key,
                                $debug                 = false,
                                $fqdn                  = $::fqdn,
                                $api_result_limit      = 2000,
                                $recaptcha_public_key  = 'fake_public_key',
                                $recaptcha_private_key = 'fake_private_key',
                                $recaptcha_use_ssl     = false,
                                $email_hostname        = 'localhost',
                                $email_port            = 25,
                                $smpp_hostname         = 'smpptrans.smsapi.org',
                                $smpp_port             = 2775,
                                $smpp_id               = 'xxxxxxxx',
                                $smpp_password         = 'xxxxxxxxxxx',
                                $smpp_source_address   = '+1234567',
                                $smpp_timeout          = 300,
                                $smpp_msg              = 'Kindly enter following code on your screen to complete the registration - ') {

  include rjil::aptrepos

  class { 'memcached':
    listen_ip => '127.0.0.1',
    tcp_port  => '11211',
    udp_port  => '11211',
  }

  if ($debug) {
    $django_debug = 'True'
  } else {
    $django_debug = 'False'
  }

  class { 'horizon':
    fqdn                    => $fqdn,
    cache_server_ip         => '127.0.0.1',
    cache_server_port       => '11211',
    secret_key              => $secret_key,
    swift                   => false,
    django_debug            => $django_debug,
    api_result_limit        => $api_result_limit,
    keystone_url            => $keystone_url,
    local_settings_template => 'rjil/local_settings.py.erb'
  }
}
