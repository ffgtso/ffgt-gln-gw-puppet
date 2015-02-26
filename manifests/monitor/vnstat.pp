class ffgt_gln_gw::monitor::vnstat () {

  ffgt_gln_gw::monitor::nrpe::check_command {
    "vnstatd":
      command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -w 1:1 -C vnstatd';
  }

  package { 
    'vnstat': 
      ensure => installed; 
  }

  service {
    'vnstat':
      ensure  => running,
      enable  => true,
      hasrestart => true,
      require => [Package['vnstat']];
  }
}

define ffgt_gln_gw::monitor::vnstat::device() {
  include ffgt_gln_gw::monitor::vnstat
 
  exec { "vnstat device ${name}":
    command => "/usr/bin/vnstat -u -i ${name}",
    require => [Package['vnstat']],
    notify => [Service['vnstat']];
  }
}
