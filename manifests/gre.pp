define ff_gln_gw::gre::tunnel (
  $gre_yaml, # YAML data file for creating GRE tunnels
) {
  file { "/tmp/prepare-gre-tunnels-${name}.sh":
    mode => "0755",
    content => template("ff_gln_gw/etc/network/prepare-xyz-tunnels.erb")
  } ->
  exec { "prepare-gre-tunnels-${mesh_code}":
    command => "/tmp/prepare-gre-tunnels-${name}.sh",
    cwd => "/tmp"
  }
}
