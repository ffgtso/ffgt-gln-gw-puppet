class ff_gln_gw::auto_gen_tunnel (
  $ipv4base = "10.234",          # Base of a /16 IPv4 network
  $ipv6base = "2a06:e881:1705:0" # Base of a /52 IPv6 network
) {
  file {
    '/usr/local/bin/tun-ip.sh':
      ensure => file,
      mode => "0755",
      owner => root,
      group => root,
      content => template("ff_gln_gw/usr/local/bin/tun-ip.sh.erb");
  }
}

