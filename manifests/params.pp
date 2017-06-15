class ff_gln_gw::params (
  $router_id, # This hosts router identifier, e.g. 10.35.0.1
  $icvpn_as,  # Main AS number of this host, e.g. 65035
              # This number will be used for the main bird configuration
  $wan_devices, # Network devices which are in the wan zone
  $debian_mirror = 'http://ftp.de.debian.org/debian/',
  $include_bird4 = true, # support bird
  $include_bird6 = true, # support bird6
  $include_chaos_routes = "no",
  $include_dn42_routes = "no",
  $provides_uplink = "no",
  $ipv6_main_prefix = "",
  $loopback_ipv6 = "::1/128",
  $loopback_ipv4 = "127.0.0.1",
  # Default values for ff_gln_gw config
  $maintenance = 0, # Shall the maintenance mode be active after installation
) {
}
