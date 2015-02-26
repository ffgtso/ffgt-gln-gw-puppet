class ffgt_gln_gw::icvpn (
  $router_id = $ffgt_gln_gw::params::router_id,
  $icvpn_as = $ffgt_gln_gw::params::icvpn_as,
) inherits ffgt_gln_gw::params {
  $tinc_name = $name

}

define ffgt_gln_gw::icvpn::setup (
  $icvpn_as,
  $icvpn_ipv4_address,
  $icvpn_ipv6_address,
  $icvpn_exclude_peerings = [],

  $tinc_keyfile,
  ){

  include ffgt_gln_gw::resources::meta

  ffgt_gln_gw::resources::ffgt_gln_gw::field {
    "ICVPN": value => '1';
    "ICVPN_EXCLUDE": value => "${icvpn_exclude_peerings}";
  }

  class { 'ffgt_gln_gw::tinc': 
    tinc_name    => $name,
    tinc_keyfile => $tinc_keyfile,

    icvpn_ipv4_address => $icvpn_ipv4_address,
    icvpn_ipv6_address => $icvpn_ipv6_address,

    icvpn_peers  => $icvpn_peerings;
  }

  if $ffgt_gln_gw::params::include_bird4 == false and $ffgt_gln_gw::params::include_bird6 == false {
    fail("At least bird4 or bird6 needs to be activated for ICVPN.")
  }

  if $ffgt_gln_gw::params::include_bird4 {
    ffgt_gln_gw::bird4::icvpn { $name:
      icvpn_as => $icvpn_as,
      icvpn_ipv4_address => $icvpn_ipv4_address,
      icvpn_ipv6_address => $icvpn_ipv6_address,
      tinc_keyfile => $tinc_keyfile }
  }
  if $ffgt_gln_gw::params::include_bird6 {
    ffgt_gln_gw::bird6::icvpn { $name:
      icvpn_as => $icvpn_as,
      icvpn_ipv4_address => $icvpn_ipv4_address,
      icvpn_ipv6_address => $icvpn_ipv6_address,
      tinc_keyfile => $tinc_keyfile }
  }
}
