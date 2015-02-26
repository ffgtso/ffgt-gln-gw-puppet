class ffgt_gln_gw::resources::bird (
  $include_bird4 = $ffgt_gln_gw::params::include_bird4,
  $include_bird6 = $ffgt_gln_gw::params::include_bird6,
) inherits ffgt_gln_gw::params {
  file {
   '/etc/bird/':
     ensure => directory,
     mode => '0755';
   '/etc/apt/preferences.d/bird':
     ensure => file,
     mode => "0644",
     owner => root,
     group => root,
     source => "puppet:///modules/ffgt_gln_gw/etc/apt/preferences.d/bird";
  }

  ffgt_gln_gw::firewall::service { "bird":
    ports  => ['179'],
    protos => ['tcp'],
    chains => ['mesh']
  }

  ffgt_gln_gw::resources::ffgt_gln_gw::field {
    "INCLUDE_BIRD4": value => $include_bird4;
    "INCLUDE_BIRD6": value => $include_bird6;
  }

}
