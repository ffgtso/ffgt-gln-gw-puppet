class ffgt_gln_gw::mosh {

  require ffgt_gln_gw::resources::repos

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
     source => "puppet:///modules/ffgt_gln_gw/etc/apt/preferences.d/mosh";
  }

  ffgt_gln_gw::firewall::service { "mosh":
    protos => ['udp'],
    ports  => ['60000-61000'],
    chains => ['wan']
  }
}
