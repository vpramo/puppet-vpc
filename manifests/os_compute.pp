class rjil::os_compute(
$package_list = [
     'python-oslo-concurrency',
     'python-paste',
     'python-pastedeploy',
     'python-routes',
     'python-oslo-db',
     'python-pyasn1',
     'python-requests',
     'python-debtcollector',
     'python-psutil',
     'python-lxml',
     'nova-common',
     'python-rfc3986',
     'python-rbd',
     'python-jinja2',
     'nova-compute',
     'python-oslo-log',
     'python-oslo-messaging',
     'python-oslo-rootwrap',
     'python-metricgenerator',
     'python-logbook',
],
)  {
  user {'nova':
         ensure => 'present'
      }

  package{$package_list:
          ensure => present,
          require => [User['nova']]
  }

  file{'/etc/nova/nova.conf':
        owner => 'nova',
        group => 'nova',
        source => "puppet:///modules/rjil/nova-compute.conf",
        require => Package['nova-compute']
    }

 service{'nova-compute':
         ensure=> running,
         require => File['/etc/nova/nova.conf']

      }
}




