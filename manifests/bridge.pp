define ff_gln_gw::bridge( $mesh_code
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
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl

  ff_gln_gw::monitor::vnstat::device { "br-${mesh_code}": }

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/${mesh_code}-bridge.cfg":
      ensure => file, 
      content => template('ff_gln_gw/etc/network/mesh-bridge.erb');
  } -> 
  exec {
    "start_bridge_interface_${mesh_code}":
      command => "/sbin/ifup br-${mesh_code}",
      unless  => "/bin/ip link show dev br-${mesh_code} 2> /dev/null",
      before  => Ff_gln_gw::Monitor::Vnstat::Device["br-${mesh_code}"],
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl] 
                 ];
  } ->
  ff_gln_gw::firewall::device { "br-${mesh_code}":
    chain => "mesh"
  } ->
  ff_gln_gw::firewall::forward { "br-${mesh_code}":
    chain => "mesh"
  }
}
