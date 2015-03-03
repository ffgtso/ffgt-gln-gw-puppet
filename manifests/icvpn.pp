class ff_gln_gw::icvpn (
  $router_id = $ff_gln_gw::params::router_id,
  $icvpn_as = $ff_gln_gw::params::icvpn_as,
) inherits ff_gln_gw::params {
  $tinc_name = $name

}

define ff_gln_gw::icvpn::setup (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ff_gln_gw::resources::meta

  ff_gln_gw::resources::ff_gln_gw::field {
    "ICVPN": value => '1';
    "ICVPN_EXCLUDE": value => "${icvpn_exclude_peerings}";
  }

  class { 'ff_gln_gw::tinc': 
    tinc_name    => $name,
    tinc_keyfile => $tinc_keyfile,

    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,

    icvpn_peers  => $icvpn_peerings;
  }

  if $ff_gln_gw::params::include_bird4 == false and $ff_gln_gw::params::include_bird6 == false {
    fail("At least bird4 or bird6 needs to be activated for ICVPN.")
  }

  if $ff_gln_gw::params::include_bird4 {
    ff_gln_gw::bird4::icvpn { $name:
      icvpn_as => $icvpn_as,
      icvpn_ipv4_address => $icvpn_ipv4_address,
      icvpn_ipv6_address => $icvpn_ipv6_address,
      tinc_keyfile => $tinc_keyfile }
  }
  if $ff_gln_gw::params::include_bird6 {
    ff_gln_gw::bird6::icvpn { $name:
      icvpn_as => $icvpn_as,
      icvpn_ipv4_address => $icvpn_ipv4_address,
      icvpn_ipv6_address => $icvpn_ipv6_address,
      tinc_keyfile => $tinc_keyfile }
  }
}
