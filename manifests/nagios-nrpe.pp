class ff_gln_gw::nagios-nrpe {
  package {
    'nagios-nrpe-server":
      ensure => installed,
  }
  service {
    'nagios-nrpe-server':
      ensure => running,
      enable => true,
      hasrestart => true,
      require => [Package['nagios-nrpe-server']];
  }
}
