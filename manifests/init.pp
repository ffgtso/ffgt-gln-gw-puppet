define ff_gln_gw::mesh(
  $mesh_name,        # Name of your community, e.g.: Freifunk Gotham City
  $mesh_code,        # Code of your community, e.g.: ffgc
  $mesh_as,          # AS of your community
  $mesh_mac,         # mac address mesh device: 52:54:00:bd:e6:d4
  $mesh_mtu = 1426,  # mtu used, default only suitable for fastd via ipv4
  $range_ipv4,       # ipv4 range allocated to community in cidr notation, e.g. 10.35.0.1/16
  $mesh_ipv4,        # ipv4 address in cidr notation, e.g. 10.35.0.1/19
  $mesh_ipv6,        # ipv6 address in cidr notation, e.g. fd35:f308:a922::ff00/64
  $mesh_peerings,    # path to the local peerings description yaml file

  $fastd_peers_git,  # fastd peers
  $fastd_bb_git,     # fastd backbone peers
  $fastd_secret,     # fastd secret
  $fastd_port,       # fastd port
  $peer_limit = -1,  # optionally set peer limit
  $use_blacklist = "no",        # optionally use a blacklist approach; set to "yes" to enable

  $dhcp_ranges = [], # dhcp pool
  $dns_servers = [], # other dns servers in your network
) {

  # TODO We should handle parameters in a param class pattern.
  # TODO Handle all git repos and other external sources in
  #      a configuration class, so we can redefine sources.
  # TODO Update README

  include ff_gln_gw::ntp
  include ff_gln_gw::maintenance
  include ff_gln_gw::firewall

  # Determine ipv{4,6} network prefixes and ivp4 netmask
  $mesh_ipv4_prefix    = ip_prefix($mesh_ipv4)
  $mesh_ipv4_prefixlen = ip_prefixlen($mesh_ipv4)
  $mesh_ipv4_netmask   = ip_netmask($mesh_ipv4)
  $mesh_ipv4_address   = ip_address($mesh_ipv4)

  $mesh_ipv6_prefix    = ip_prefix($mesh_ipv6)
  $mesh_ipv6_prefixlen = ip_prefixlen($mesh_ipv6)
  $mesh_ipv6_address   = ip_address($mesh_ipv6)

  Class['ff_gln_gw::firewall'] ->
  ff_gln_gw::bridge { "bridge_${mesh_code}":
    mesh_name            => $mesh_name,
    mesh_code            => $mesh_code,
    mesh_ipv6_address    => $mesh_ipv6_address,
    mesh_ipv6_prefix     => $mesh_ipv6_prefix,
    mesh_ipv6_prefixlen  => $mesh_ipv6_prefixlen,
    mesh_ipv4_address    => $mesh_ipv4_address,
    mesh_ipv4_netmask    => $mesh_ipv4_netmask,
    mesh_ipv4_prefix     => $mesh_ipv4_prefix,
    mesh_ipv4_prefixlen  => $mesh_ipv4_prefixlen
  } ->
  Class['ff_gln_gw::ntp'] ->
  ff_gln_gw::ntp::allow { "${mesh_code}":
    ipv4_net => $mesh_ipv4,
    ipv6_net => $mesh_ipv6
  } ->
  ff_gln_gw::dhcpd { "br-${mesh_code}":
    mesh_code    => $mesh_code,
    ipv4_address => $mesh_ipv4_address,
    ipv4_network => $mesh_ipv4_prefix,
    ipv4_netmask => $mesh_ipv4_netmask,
    ranges       => $dhcp_ranges,
    dns_servers  => $dns_servers;
  } ->
  ff_gln_gw::fastd { "fastd_${mesh_code}":
    mesh_name => $mesh_name,
    mesh_code => $mesh_code,
    mesh_mac  => $mesh_mac,
    mesh_mtu  => $mesh_mtu,
    fastd_secret => $fastd_secret,
    fastd_port   => $fastd_port,
    peer_limit => $peer_limit,
    use_blacklist => $use_blacklist,
    fastd_peers_git => $fastd_peers_git,
    fastd_bb_git => $fastd_bb_git;
  } ->
  ff_gln_gw::radvd { "br-${mesh_code}":
    mesh_ipv6_address    => $mesh_ipv6_address,
    mesh_ipv6_prefix     => $mesh_ipv6_prefix,
    mesh_ipv6_prefixlen  => $mesh_ipv6_prefixlen;
  } ->
  ff_gln_gw::named::listen { "${mesh_code}":
    ipv4_address => $mesh_ipv4_address,
    ipv6_address => $mesh_ipv6_address,
  } ->
  ff_gln_gw::named::allow {
    "${mesh_code}_v4":
      ip_prefix    => $mesh_ipv4_prefix,
      ip_prefixlen => $mesh_ipv4_prefixlen;
    "${mesh_code}_v6":
      ip_prefix    => $mesh_ipv6_prefix,
      ip_prefixlen => $mesh_ipv6_prefixlen;
  }

  if $ff_gln_gw::params::include_bird6 {
    ff_gln_gw::bird6::mesh { "bird6-${mesh_code}":
      mesh_code => $mesh_code,
      mesh_ipv4_address => $mesh_ipv4_address,
      mesh_ipv6_address => $mesh_ipv6_address,
      mesh_peerings => $mesh_peerings,
      site_ipv6_prefix => $mesh_ipv6_prefix,
      site_ipv6_prefixlen => $mesh_ipv6_prefixlen,
      icvpn_as => $mesh_as;
    }
  }
  if $ff_gln_gw::params::include_bird4 {
    ff_gln_gw::bird4::mesh { "bird4-${mesh_code}":
      mesh_code => $mesh_code,
      mesh_ipv4_address => $mesh_ipv4_address,
      range_ipv4 => $range_ipv4,
      mesh_ipv6_address => $mesh_ipv6_address,
      mesh_peerings => $mesh_peerings,
      site_ipv4_prefix => $mesh_ipv4_prefix,
      site_ipv4_prefixlen => $mesh_ipv4_prefixlen,
      icvpn_as => $mesh_as;
    }
  }
 
  # ff_gln_gw::opkg::mirror
  # ff_gln_gw::firmware mirror
}


define ff_gln_gw::gateway(
  $mesh_name,        # Name of your community, e.g.: Freifunk Gotham City
  $mesh_code,        # Code of your community, e.g.: ffgc
  $range_ipv4,       # ipv4 range allocated to community in cidr notation, e.g. 10.35.0.1/16
  $range_ipv6,       # ipv6 range allocated to community (public v6 prefferred)
  $mesh_peerings,    # path to the local peerings description yaml file
  $have_mesh_peerings,
)  inherits ff_gln_gw::params {

  # TODO We should handle parameters in a param class pattern.
  # TODO Handle all git repos and other external sources in
  #      a configuration class, so we can redefine sources.
  # TODO Update README

  include ff_gln_gw::ntp
  include ff_gln_gw::maintenance
  include ff_gln_gw::firewall

  # Determine ipv{4,6} network prefixes and ivp4 netmask
  $mesh_ipv4_prefix    = ip_prefix($range_ipv4)
  $mesh_ipv4_prefixlen = ip_prefixlen($range_ipv4)
  $mesh_ipv4_netmask   = ip_netmask($range_ipv4)
  $mesh_ipv4_address   = ip_address($range_ipv4)

  $mesh_ipv6_prefix    = ip_prefix($range_ipv6)
  $mesh_ipv6_prefixlen = ip_prefixlen($range_ipv6)
  $mesh_ipv6_address   = ip_address($range_ipv6)

  Class['ff_gln_gw::ntp'] ->
  ff_gln_gw::ntp::allow { "${mesh_code}":
    ipv4_net => $range_ipv4,
    ipv6_net => $range_ipv6
  } ->
  ff_gln_gw::named::listen { "${mesh_code}":
    ipv4_address => $ff_gln_gw::params::router_id,
    ipv6_address => $mesh_ipv6_address,
  } ->
  ff_gln_gw::named::allow {
    "${mesh_code}_v4":
      ip_prefix    => $mesh_ipv4_prefix,
      ip_prefixlen => $mesh_ipv4_prefixlen;
    "${mesh_code}_v6":
      ip_prefix    => $mesh_ipv6_prefix,
      ip_prefixlen => $mesh_ipv6_prefixlen;
  }

  if $ff_gln_gw::params::include_bird6 {
    ff_gln_gw::bird6::mesh { "bird6-${mesh_code}":
      mesh_code => $mesh_code,
      mesh_ipv4_address => $mesh_ipv4_address,
      mesh_ipv6_address => $mesh_ipv6_address,
      mesh_peerings => $mesh_peerings,
      have_mesh_peerings => $have_mesh_peerings,
      site_ipv6_prefix => $mesh_ipv6_prefix,
      site_ipv6_prefixlen => $mesh_ipv6_prefixlen,
      icvpn_as => $ff_gln_gw::params::icvpn_as;
    }
  }
  if $ff_gln_gw::params::include_bird4 {
    ff_gln_gw::bird4::mesh { "bird4-${mesh_code}":
      mesh_code => $mesh_code,
      mesh_ipv4_address => $mesh_ipv4_address,
      range_ipv4 => $range_ipv4,
      mesh_ipv6_address => $mesh_ipv6_address,
      mesh_peerings => $mesh_peerings,
      have_mesh_peerings => $have_mesh_peerings,
      site_ipv4_prefix => $mesh_ipv4_prefix,
      site_ipv4_prefixlen => $mesh_ipv4_prefixlen,
      icvpn_as => $ff_gln_gw::params::icvpn_as;
    }
  }

  # ff_gln_gw::opkg::mirror
  # ff_gln_gw::firmware mirror
}