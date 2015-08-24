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
    path => '/etc/bird/bird.conf',
    line => "include \"/etc/bird/bird.conf.d/uplink.conf\";",
    require => File['/etc/bird/bird.conf'],
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

  $endpoint_name = $name
  $local_ip = ip_address($local_ipv4)
  $local_netmask = ip_netmask($local_ipv4)

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


class ff_gln_gw::uplink::static (
  $endpoint_ip,
  $do_nat = "no",
  $nat_ip = "127.0.0.1"
) inherits ff_gln_gw::params {

  include ff_gln_gw::firewall
  include ff_gln_gw::resources::sysctl
  include ff_gln_gw::bird4

  $endpoint_name = $name
  $nat_ip = ip_address($nat_network)
  $nat_netmask = ip_netmask($nat_network)

  Exec { path => [ "/bin" ] }
  kmod::load { 'dummy':
    ensure => present,
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
    path => '/etc/bird/bird.conf',
    line => "include \"/etc/bird/bird.conf.d/static-uplink.conf\";",
    require => File['/etc/bird/bird.conf'],
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
