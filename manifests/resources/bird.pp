class ff_gln_gw::resources::bird (
  $include_bird4 = $ff_gln_gw::params::include_bird4,
  $include_bird6 = $ff_gln_gw::params::include_bird6,
) inherits ff_gln_gw::params {
  file {
   '/etc/bird/':
     ensure => directory,
     mode => '0755';
   '/etc/apt/preferences.d/bird':
     ensure => file,
     mode => "0644",
     owner => root,
     group => root,
     source => "puppet:///modules/ff_gln_gw/etc/apt/preferences.d/bird";
  }

  ff_gln_gw::firewall::service { "bird":
    ports  => ['179'],
    protos => ['tcp'],
    chains => ['mesh']
  }

  ff_gln_gw::resources::ff_gln_gw::field {
    "INCLUDE_BIRD4": value => $include_bird4;
    "INCLUDE_BIRD6": value => $include_bird6;
  }

}
