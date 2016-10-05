class ff_gln_gw::auto_gen_tunnel (
  $ipv4base, # "10.234",
  $ipv6base  # "2a03:2260:117:0"
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

