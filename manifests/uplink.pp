class ff_gln_gw::uplink ( 
  $gw_control_ip     = "8.8.8.8",     # Control ip addr 
  $gw_bandwidth      = 100,           # How much bandwith we should have up/down per mesh interface
) {

  include ff_gln_gw::resources::ff_gln_gw

  class {
    'ff_gln_gw::resources::checkgw':
      gw_control_ip => $gw_control_ip,
      gw_bandwidth => $gw_bandwidth,
  }
}


class ff_gln_gw::uplink::ip (
  $nat_network,
  $tunnel_network = "127.0.0.0/8",
) inherits ff_gln_gw::params {
  include ff_gln_gw::firewall
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::bird4

  $nat_ip = ip_address($nat_network)
  $nat_netmask = ip_netmask($nat_network)

  Exec { path => [ "/bin" ] }
  kmod::load { 'dummy':
    ensure => present,
  }

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/dummy0":
      ensure => file,
      content => template("ff_gln_gw/etc/network/uplink-dummy.erb");
  } ->
  exec {
    "start_dummy_interface_0":
      command => "/sbin/ifup dummy0",
      unless  => "/bin/ip link show dev dummy0 | grep 'DOWN|dummy0' 2> /dev/null",
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  }

  class { 'ff_gln_gw::uplink': }
 
  # Define Firewall rule for masquerade
  file {
    '/etc/iptables.d/910-Masquerade-uplink':
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0644',
       content => inline_template("ip4tables -t nat -A POSTROUTING -o uplink-+ ! -d <%=@tunnel_network%> -j SNAT --to <%=@nat_ip%>"),
       require => [File['/etc/iptables.d/']];
     '/etc/iptables.d/910-Clamp-mss':
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0644',
       content => 'ip4tables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu',
       require => [File['/etc/iptables.d/']];
  }

  file_line { "bird-uplink-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/uplink.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }
}


class ff_gln_gw::uplink::natip () inherits ff_gln_gw::params {
  include ff_gln_gw::firewall
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::bird4

  Exec { path => [ "/bin" ] }
  kmod::load { 'dummy':
    ensure => present,
  }

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/dummy0":
      ensure => file,
      content => template("ff_gln_gw/etc/network/uplink-dummy-nat.erb");
  } ->
  exec {
    "start_dummy_interface_0":
      command => "/sbin/ifup dummy0",
      unless  => "/bin/ip link show dev dummy0 | grep 'DOWN|dummy0' 2> /dev/null",
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  }

  class { 'ff_gln_gw::uplink': }

  # Define Firewall rule for masquerade
  file {
     '/etc/iptables.d/910-Clamp-mss':
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0644',
       content => 'ip4tables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu',
       require => [File['/etc/iptables.d/']];
  }

  file_line { "bird-uplink-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/uplink.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink-nat.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }
}


class ff_gln_gw::uplink::ipv6 () inherits ff_gln_gw::params {
  include ff_gln_gw::firewall
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::bird6

  file_line { "bird6-uplink-include":
    path => '/etc/bird/bird6.conf.inc',
    line => "include \"/etc/bird/bird6.conf.d/uplink.conf\";",
    require => File['/etc/bird/bird6.conf.inc'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/uplink.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.uplink.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird6-uplink-include"],
      Service['bird6']
    ]
  }
}


class ff_gln_gw::uplink::provide (
  $nat_network,
  $tunnel_network,
  $uplink_as,
) inherits ff_gln_gw::params {
  include ff_gln_gw::firewall
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::bird4

  $nat_ip = ip_address($nat_network)
  $nat_prefix = ip_prefix($nat_network)
  $nat_prefixlen = ip_prefixlen($nat_network)
  $nat_netmask = ip_netmask($nat_network)

  class { 'ff_gln_gw::uplink': }

  file_line { "bird-uplink-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/uplink.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink-provide.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }
}


class ff_gln_gw::uplink::bgp (
  $nat_network = "127.0.0.1/32",
  $tunnel_network = "127.0.0.0/8",
  $do_nat = "yes"
) inherits ff_gln_gw::params {
  include ff_gln_gw::firewall
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::bird4

  if $do_nat == "yes" {
    $nat_ip = ip_address($nat_network)
    $nat_netmask = ip_netmask($nat_network)

    Exec { path => [ "/bin" ] }
    kmod::load { 'dummy':
      ensure => present,
    }

    Class['ff_gln_gw::resources::network'] ->
    file {
      "/etc/network/interfaces.d/dummy0":
        ensure => file,
        content => template("ff_gln_gw/etc/network/uplink-dummy.erb");
    } ->
    exec {
      "start_dummy_interface_0":
        command => "/sbin/ifup dummy0",
        unless  => "/bin/ip link show dev dummy0 | grep 'DOWN|dummy0' 2> /dev/null",
        require => [ File_Line["/etc/iproute2/rt_tables"]
                   , Class[ff_gln_gw::resources::sysctl]
                   ];
    }
  }

  class { 'ff_gln_gw::uplink': }

  if $do_nat == "yes" {
    # Define Firewall rule for masquerade
    file {
      '/etc/iptables.d/910-Masquerade-uplink':
         ensure => file,
         owner => 'root',
         group => 'root',
         mode => '0644',
         content => inline_template("ip4tables -t nat -A POSTROUTING -o uplink-+ ! -d <%=@tunnel_network%> -j SNAT --to <%=@nat_ip%>"),
         require => [File['/etc/iptables.d/']];
       '/etc/iptables.d/910-Clamp-mss':
         ensure => file,
         owner => 'root',
         group => 'root',
         mode => '0644',
         content => 'ip4tables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu',
         require => [File['/etc/iptables.d/']];
    }
  }

  file_line { "bird-uplink-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/uplink.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }
}


define ff_gln_gw::uplink::tunnel (
  $local_public_ip,
  $remote_public_ip,
  $local_ipv4,
  $tunnel_mtu = 1426,
  $remote_ip,
  $remote_as,
) {
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::firewall
  include ff_gln_gw::bird4

  $provides_uplink = $ff_gln_gw::params::provides_uplink

  $endpoint_name = $name
  $local_ip = ip_address($local_ipv4)
  $local_netmask = ip_netmask($local_ipv4)
  $rem_ip = ip_address($remote_ip)
  $rem_prefix = ip_prefix($remote_ip)
  $rem_prefixlen = ip_prefixlen($remote_ip)

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/uplink-${endpoint_name}":
      ensure => file,
      content => template("ff_gln_gw/etc/network/uplink-gre.erb");
  } ->
  exec {
    "start_uplink_${endpoint_name}_interface":
      command => "/sbin/ifup uplink-${endpoint_name}",
      unless  => "/bin/ip link show dev uplink-${endpoint_name}' 2> /dev/null",
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  }

  file_line { "bird-uplink-${endpoint_name}-include":
    path => '/etc/bird/bird.conf.d/uplink.conf',
    line => "include \"/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf\";",
    require => File['/etc/bird/bird.conf.d/uplink.conf'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink.peer.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }

  ff_gln_gw::firewall::forward { "uplink-${name}":
    chain => 'mesh'
  }
}

# Sets up a tunnel for v4 & v6, expects /64 for v6 P2P link ...
define ff_gln_gw::uplink::tunnelDS (
  $local_public_ip,
  $remote_public_ip,
  $local_ipv6,
  $remote_ipv6,
  $local_ipv4,
  $remote_ip,              # really should be "remote_ipv4" FIXME!
  $tunnel_mtu = 1426,
  $v6_network,
  $remote_as,
  $bgp_local_pref = 100,
  $bgp_local_pref6 = -1,
  $mesh_code
) {
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::firewall
  include ff_gln_gw::bird4
  include ff_gln_gw::bird6

  if $bgp_local_pref6 == -1 {
    $bgp_local_pref6 = $bgp_local_pref
  }

  $provides_uplink = $ff_gln_gw::params::provides_uplink
  $icvpn_as  = $ff_gln_gw::params::icvpn_as

  $endpoint_name = $name
  $local_ip = ip_address($local_ipv4)
  $local_netmask = ip_netmask($local_ipv4)
  $rem_ip = ip_address($remote_ip)
  $rem_prefix = ip_prefix($remote_ip)
  $rem_prefixlen = ip_prefixlen($remote_ip)
  $local_ipv6_ip = ip_address("${local_ipv6}/64")
  $local_ipv6_prefix = ip_prefix("${local_ipv6}/64")
  $local_ipv6_prefixlen = ip_prefixlen("${local_ipv6}/64")

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/uplink-${endpoint_name}":
      ensure => file,
      content => template("ff_gln_gw/etc/network/uplink-gre-DS.erb");
  } ->
  exec {
    "start_uplink_${endpoint_name}_interface":
      command => "/sbin/ifup uplink-${endpoint_name}",
      unless  => "/bin/ip link show dev uplink-${endpoint_name}' 2> /dev/null",
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  }

  file_line { "bird-uplink-${endpoint_name}-include":
    path => '/etc/bird/bird.conf.d/uplink.conf',
    line => "include \"/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf\";",
    require => File['/etc/bird/bird.conf.d/uplink.conf'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink.peer.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }

  file_line { "bird6-uplink-${endpoint_name}-include":
    path => '/etc/bird/bird6.conf.d/uplink.conf',
    line => "include \"/etc/bird/bird6.conf.d/uplink.${endpoint_name}.conf\";",
    require => File['/etc/bird/bird6.conf.d/uplink.conf'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/uplink.${endpoint_name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.uplink.peer.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird6-uplink-include"],
      Service['bird6']
    ]
  }

  ff_gln_gw::firewall::forward { "uplink-${name}":
    chain => 'mesh'
  }
}


define ff_gln_gw::uplink::nattunnel (
  $local_public_ip,
  $remote_public_ip,
  $local_ipv4,
  $tunnel_mtu = 1426,
  $remote_ip,
  $remote_as,
  $nat_network,
  $tunnel_network = "127.0.0.0/8",
  $bgp_local_pref = 100,
  $mesh_code
) {
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::firewall
  include ff_gln_gw::bird4

  $nat_ip = ip_address($nat_network)
  $nat_netmask = ip_netmask($nat_network)
  $nat_prefixlen = ip_prefixlen($nat_network)

  $provides_uplink = $ff_gln_gw::params::provides_uplink

  $endpoint_name = $name
  $local_ip = ip_address($local_ipv4)
  $local_netmask = ip_netmask($local_ipv4)
  $rem_ip = ip_address($remote_ip)
  $rem_prefix = ip_prefix($remote_ip)
  $rem_prefixlen = ip_prefixlen($remote_ip)

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/uplink-${endpoint_name}":
      ensure => file,
      content => template("ff_gln_gw/etc/network/uplink-gre.erb");
  } ->
  exec {
    "start_uplink_${endpoint_name}_interface":
      command => "/sbin/ifup uplink-${endpoint_name}",
      unless  => "/bin/ip link show dev uplink-${endpoint_name}' 2> /dev/null",
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  }

  file_line { "bird-uplink-${endpoint_name}-include":
    path => '/etc/bird/bird.conf.d/uplink.conf',
    line => "include \"/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf\";",
    require => File['/etc/bird/bird.conf.d/uplink.conf'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink.peer-nat.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }

  file_line { "dummy0-${endpoint_name}-addr":
    path => '/etc/network/interfaces.d/dummy0',
    line => "  post-up ip -4 addr add ${nat_network} dev \$IFACE\n  pre-down ip -4 addr del ${nat_network} dev \$IFACE",
  } ->
  exec {
    "restart_dummy_interface_0-${endpoint_name}":
      command => "/sbin/ifdown dummy0 && /sbin/ifup dummy0",
      unless  => "/bin/ip link show dev dummy0 | grep 'dummy0' 2> /dev/null";
  }

  ff_gln_gw::firewall::forward { "uplink-${name}":
    chain => 'mesh'
  }

  # Define Firewall rule for masquerade
  file {
    "/etc/iptables.d/910-Masquerade-uplink-${endpoint_name}":
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0644',
       content => inline_template("ip4tables -t nat -A POSTROUTING -o uplink-<%=@endpoint_name%> ! -d <%=@tunnel_network%> -j SNAT --to <%=@nat_ip%>"),
       require => [File['/etc/iptables.d/']];
  }
}


define ff_gln_gw::uplink::nattunnelDS (
  $local_public_ip,
  $remote_public_ip,
  $local_ipv4,
  $remote_ip,
  $tunnel_mtu = 1426,
  $local_ipv6,
  $remote_ipv6,
  $remote_as,
  $nat_network,
  $v6_network,
  $tunnel_network = "127.0.0.0/8",
  $bgp_local_pref = 100,
  $bgp_local_pref6 = -1,
  $mesh_code
) {
  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::firewall
  include ff_gln_gw::bird4
  include ff_gln_gw::bird4

  if $bgp_local_pref6 == -1 {
    $bgp_local_pref6 = $bgp_local_pref
  }

  $nat_ip = ip_address($nat_network)
  $nat_netmask = ip_netmask($nat_network)
  $nat_prefixlen = ip_prefixlen($nat_network)

  $provides_uplink = $ff_gln_gw::params::provides_uplink
  $icvpn_as  = $ff_gln_gw::params::icvpn_as

  $endpoint_name = $name
  $local_ip = ip_address($local_ipv4)
  $local_netmask = ip_netmask($local_ipv4)
  $rem_ip = ip_address($remote_ip)
  $rem_prefix = ip_prefix($remote_ip)
  $rem_prefixlen = ip_prefixlen($remote_ip)
  $local_ipv6_ip = ip_address("${local_ipv6}/64")
  $local_ipv6_prefix = ip_prefix("${local_ipv6}/64")
  $local_ipv6_prefixlen = ip_prefixlen("${local_ipv6}/64")

  Class['ff_gln_gw::resources::network'] ->
  file {
    "/etc/network/interfaces.d/uplink-${endpoint_name}":
      ensure => file,
      content => template("ff_gln_gw/etc/network/uplink-gre-DS.erb");
  } ->
  exec {
    "start_uplink_${endpoint_name}_interface":
      command => "/sbin/ifup uplink-${endpoint_name}",
      unless  => "/bin/ip link show dev uplink-${endpoint_name}' 2> /dev/null",
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  }

  file_line { "bird-uplink-${endpoint_name}-include":
    path => '/etc/bird/bird.conf.d/uplink.conf',
    line => "include \"/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf\";",
    require => File['/etc/bird/bird.conf.d/uplink.conf'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/uplink.${endpoint_name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.uplink.peer-nat.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }

  file_line { "bird6-uplink-${endpoint_name}-include":
    path => '/etc/bird/bird6.conf.d/uplink.conf',
    line => "include \"/etc/bird/bird6.conf.d/uplink.${endpoint_name}.conf\";",
    require => File['/etc/bird/bird6.conf.d/uplink.conf'],
    notify  => Service['bird6'];
  }

  file { "/etc/bird/bird6.conf.d/uplink.${endpoint_name}.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird6.uplink.peer.conf.erb"),
    require => [File['/etc/bird/bird6.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird6-uplink-include"],
      Service['bird6']
    ]
  }

  file_line { "dummy0-${endpoint_name}-addr":
    path => '/etc/network/interfaces.d/dummy0',
    line => "  post-up ip -4 addr add ${nat_network} dev \$IFACE\n  pre-down ip -4 addr del ${nat_network} dev \$IFACE",
  } ->
  exec {
    "restart_dummy_interface_0-${endpoint_name}":
      command => "/sbin/ifdown dummy0 && /sbin/ifup dummy0",
      unless  => "/bin/ip link show dev dummy0 | grep 'dummy0' 2> /dev/null";
  }

  ff_gln_gw::firewall::forward { "uplink-${name}":
    chain => 'mesh'
  }

  # Define Firewall rule for masquerade
  file {
    "/etc/iptables.d/910-Masquerade-uplink-${endpoint_name}":
       ensure => file,
       owner => 'root',
       group => 'root',
       mode => '0644',
       content => inline_template("ip4tables -t nat -A POSTROUTING -o uplink-<%=@endpoint_name%> ! -d <%=@tunnel_network%> -j SNAT --to <%=@nat_ip%>"),
       require => [File['/etc/iptables.d/']];
  }
}

define ff_gln_gw::uplink::static (
  $endpoint_ip,
  $do_nat = "no",
  $nat_network = "127.0.0.0/8",
  $nat_ip = "127.0.0.1"
) {

  include ff_gln_gw::resources::network
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::firewall
  include ff_gln_gw::bird4

  $endpoint_name = $name
  $nat_netmask = ip_netmask($nat_network)

  if $do_nat == "yes" {
    # Define Firewall rule for masquerade
    file {
      '/etc/iptables.d/910-Masquerade-uplink':
         ensure => file,
         owner => 'root',
         group => 'root',
         mode => '0644',
         content => inline_template("ip4tables -t nat -A POSTROUTING -s <%=@nat_network%> -j SNAT --to <%=@nat_ip%>"),
         require => [File['/etc/iptables.d/']];
       '/etc/iptables.d/910-Clamp-mss':
         ensure => file,
         owner => 'root',
         group => 'root',
         mode => '0644',
         content => 'ip4tables -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu',
         require => [File['/etc/iptables.d/']];
    }
  }

  file_line { "bird-uplink-include":
    path => '/etc/bird/bird.conf.inc',
    line => "include \"/etc/bird/bird.conf.d/static-uplink.conf\";",
    require => File['/etc/bird/bird.conf.inc'],
    notify  => Service['bird'];
  }

  file { "/etc/bird/bird.conf.d/static-uplink.conf":
    mode => "0644",
    content => template("ff_gln_gw/etc/bird/bird.static-uplink.conf.erb"),
    require => [File['/etc/bird/bird.conf.d/'],Package['bird']],
    notify  => [
      File_line["bird-uplink-include"],
      Service['bird']
    ]
  }
}
