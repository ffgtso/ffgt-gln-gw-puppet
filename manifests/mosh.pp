class ff_gln_gw::mosh {

  require ff_gln_gw::resources::repos

  package {
    'mosh':
      ensure => installed,
      require => [
        File['/etc/apt/preferences.d/mosh'],
        Apt::Source['debian-backports']
      ];
  }

  file {
   '/etc/apt/preferences.d/mosh':
     ensure => file,
     mode => "0644",
     owner => root,
     group => root,
     source => "puppet:///modules/ff_gln_gw/etc/apt/preferences.d/mosh";
  }

  ff_gln_gw::firewall::service { "mosh":
    protos => ['udp'],
    ports  => ['60000-61000'],
    chains => ['wan']
  }
}
