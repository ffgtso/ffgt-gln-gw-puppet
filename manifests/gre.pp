define ff_gln_gw::gre::tunnel (
  $gre_yaml, # YAML data file for creating XYZ tunnels (GRE, L2TP)
) {
  file { "/tmp/prepare-gre-tunnels-${name}.sh":
    mode => "0755",
    content => template("ff_gln_gw/etc/network/prepare-xyz-tunnels.erb")
  } ->
  exec { "prepare-gre-tunnels-${name}":
    command => "/tmp/prepare-gre-tunnels-${name}.sh",
    cwd => "/tmp"
  }
}
