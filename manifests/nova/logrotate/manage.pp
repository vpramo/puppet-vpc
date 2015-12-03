class rjil::nova::logrotate::manage {
    rjil::jiocloud::logrotate {'nova-manage':
        logdir => '/var/log/nova/'
    }
}