define ffgt_gln_gw::bridge( $mesh_code
                    , $mesh_name
                    , $mesh_ipv6_address
                    , $mesh_ipv6_prefix
                    , $mesh_ipv6_prefixlen
                    , $mesh_ipv4_address
                    , $mesh_ipv4_netmask
                    , $mesh_ipv4_prefix
                    , $mesh_ipv4_prefixlen

                    , $dhcp_ranges = []

                    , $dns_servers = []

                    ) {
  include ffgt_gln_gw::resources::network
  include ffgt_gln_gw::resources::sysctl

  ffgt_gln_gw::monitor::vnstat::device { "br-${mesh_code}": }

  Class['ffgt_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/${mesh_code}-bridge":
      ensure => file, 
      content => template('ffgt_gln_gw/etc/network/mesh-bridge.erb');
  } -> 
  exec {
    "start_bridge_interface_${mesh_code}":
      command => "/sbin/ifup br-${mesh_code}",
      unless  => "/bin/ip link show dev br-${mesh_code} 2> /dev/null",
      before  => Ffnord::Monitor::Vnstat::Device["br-${mesh_code}"],
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ffgt_gln_gw::resources::sysctl] 
                 ];
  } ->
  ffgt_gln_gw::firewall::device { "br-${mesh_code}":
    chain => "mesh"
  } ->
  ffgt_gln_gw::firewall::forward { "br-${mesh_code}":
    chain => "mesh"
  }
}
