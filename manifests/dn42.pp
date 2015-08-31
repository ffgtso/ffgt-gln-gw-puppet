class ff_gln_gw::dn42 (
  $router_id = $ff_gln_gw::params::router_id,
  $icvpn_as = $ff_gln_gw::params::icvpn_as,
) inherits ff_gln_gw::params {
  $tinc_name = $name

}

define ff_gln_gw::dn42::setup (
  $icvpn_as,
  $dn42_peerings,    # path to the local peerings description yaml file
){

  include ff_gln_gw::resources::meta

  if $ff_gln_gw::params::include_bird4 == false and $ff_gln_gw::params::include_bird6 == false {
    fail("At least bird4 or bird6 needs to be activated for DN42.")
  }

  if $ff_gln_gw::params::include_bird4 {
    ff_gln_gw::bird4::dn42 { $name:
      icvpn_as => $icvpn_as,
      dn42_peerings => $dn42_peerings
      }
  }
  if $ff_gln_gw::params::include_bird6 {
    ff_gln_gw::bird6::icvpn { $name:
      icvpn_as => $icvpn_as,
      dn42_peerings => $dn42_peerings
    }
  }
}
