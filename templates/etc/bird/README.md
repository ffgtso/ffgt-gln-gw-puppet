# bird configurstion #

## tbd ##

### Communities ###

    (65535:65281)              NO_EXPORT
    (65535:65282)              NO_ADVERTISE
    (65535:666)                BLACKHOLE

### Large Communities ###

    (206813:2:REMOTE_ASN)      Prepend 206813 to REMOTE_ASN
    (206813:2:0)               Prepend 206813 generally
    (206813:3:REMOTE_ASN)      Prepend 206813 2x to REMOTE_ASN
    (206813:3:0)               Prepend 206813 2x generally
    (206813:4:REMOTE_ASN)      Reject export to REMOTE_ASN
    (206813:4:0)               Reject export at all
    (206813:5:REMOTE_ASN)      Allow export to REMOTE_ASN (precedence over (206813:4:*))


Read-only:

    (206813:0:REMOTE_ASN)      Route learned from REMOTE_ASN (legacy)
    (206813:1xx:REMOTE_ASN)    Route learned from REMOTE_ASN at IXP xx
    (206813:200:0)             Route learned from peer
    (206813:200:REMOTE_ASN)    Route learned from peer REMOTE_ASN
    (206813:300:REMOTE_ASN)    Route learned from "customer" ASN
    (206813:400:0)             Route learned from transit (i. e. do not re-propagate)
    (206813:400:REMOTE_ASN)    Route learned from transit ASN







IXPs:

    01   Community-IX BER
    02   Community-IX FRA
    03   ECIX HAM
    04   DECIX HAM
    05   DECIX FRA (remote)
    06   DECIX DUS
    07   DECIX DUS (remote)
    08   DECIX MUC (remote)
    09   BCIX
    10   DECIX FRA
    11   LocIX
    12   KleyRex


## Configuration example ##

### bgp-ham02.4830.org ###

    root@chimaera:~# cat ebgp_ham02.yaml
    #…
    as32934-2-ecix:
      ipv4src: "193.42.155.83"
      ipv6src: "2001:7f8:8:10:3:27dd:0:1"
      ipv4dst: "193.42.155.19"
      ipv6dst: "2001:7f8:8:10:0:80a6:0:2"
      peeras:  "32934"
      import6: "AS-FACEBOOK"
      import4: "AS-FACEBOOK"
      export6: "AS-FFGT"
      export4: "AS-FFGT"
      reimport_filter6: "AS206813"
      reimport_filter4: "AS206813"
      name:    "AS32934_2e"
      exportlimit6: "50"
      exportlimit4: "10"

    as32934-2-decix:
      ipv4src: "80.81.203.108"
      ipv6src: "2001:7f8:3d:0:3:27dd:0:1"
      ipv4dst: "80.81.203.174"
      ipv6dst: "2001:7f8:3d::80a6:0:2"
      peeras:  "32934"
      import6: "AS-FACEBOOK"
      import4: "AS-FACEBOOK"
      export6: "AS-FFGT"
      export4: "AS-FFGT"
      reimport_filter6: "AS206813"
      reimport_filter4: "AS206813"
      name:    "AS32934_2dh"
      exportlimit6: "50"
      exportlimit4: "10"
    #…
    defrars2:
      ipv4src: "80.81.196.10"
      ipv6src: "2001:7f8::3:27dd:0:1"
      ipv4dst: "80.81.193.157"
      ipv6dst: "2001:7f8::1a27:5051:c19d"
      mode: "lan"
      peeras:  "6695"
      import6: "AS-DECIX-V6"
      import4: "AS-DECIX"
      export6: "AS-FFGT"
      export4: "AS-FFGT"
      reimport_filter6: "AS206813"
      reimport_filter4: "AS206813"
      bgpprepend: "1"
      exportlimit6: "50"
      exportlimit4: "10"
      name: "decix_fra2"
    #…

    root@chimaera:~# cat chimaera.pp
    # …
    class { 'ff_gln_gw::params':
      router_id => "193.26.120.85",
      icvpn_as => "206813",
      include_dn42_routes => "no",  # yes/no(default) to include routes from DN42
      include_chaos_routes => "no",  # yes/no(default) to include routes from ChaosVPN
      wan_devices => ['ens3'],   # A array of devices which should be in the wan zone
      ipv6_main_prefix => "2a06:e881:1702::/48",
      loopback_ipv6 => "2a06:e881:1702:1::1",
      loopback_ipv4 => "193.26.120.85",
      mesh_code    => "ffgt",
    }

    ff_gln_gw::gateway { 'ham02':
      mesh_name    => "FF KreisGT",
      mesh_code    => "ffgt",
      range_ipv6   => "2a06:e881:1702::/48",
      range_ipv4   => "193.26.120.85/32",
      mesh_peerings => "/dev/null",
      have_mesh_peerings => "no",
    }

    ff_gln_gw::gre::tunnel {
      'ham02':
        gre_yaml => "tunnel.yaml",
    }

    # …

    ff_gln_gw::bird6::ospf {
      'ffgt':
        mesh_code => "ffgt",
        range_ipv6 => "2001:bf7:1310::/44",
        ospf_peerings => "ospf-peerings.yaml",
        have_ospf_peerings => "yes",
        dfz => "true",
        ospf_export_filter => "ospf-export.inc"
    }

    ff_gln_gw::bird4::ospf {
      'ffgt':
        mesh_code => "ffgt",
        range_ipv4 => "10.255.0.0/16",
        ospf_peerings => "ospf-peerings.yaml",
        have_ospf_peerings => "yes",
        dfz => "true",
        ospf_export_filter => "ospf-export.inc"
    }

    ff_gln_gw::bird6::ibgp::setup { 'ham02': }

    ff_gln_gw::bird4::ibgp::setup { 'ham02': }

    ff_gln_gw::bird6::ibgp {
      'ham02rr':
        gre_yaml => "loopback.yaml",
        bgp_options => "rr client; next hop self; gateway recursive;",
        peers => {
          'ffgut01' => '100',
          'ffgut02' => '100',
          'fffra01' => '100',
          'gtiffany' => '100',
        }
    }

    ff_gln_gw::bird6::ibgp {
      'ham02':
        gre_yaml => "loopback.yaml",
        bgp_options => "next hop self; gateway recursive;",
        peers => {
          'ffber01' => '100',
        }
    }

    ff_gln_gw::bird4::ibgp {
      'ham02rr':
        gre_yaml => "loopback.yaml",
        bgp_options => "rr client; next hop self; gateway recursive;",
        #bgp_options => "direct;",
        peers => {
         'ffgut01' => '100',
          'ffgut02' => '100',
          'fffra01' => '100',
          'gtiffany' => '100',
        }
    }

    ff_gln_gw::bird4::ibgp {
      'ham02':
        gre_yaml => "loopback.yaml",
        bgp_options => "next hop self; gateway recursive;",
        peers => {
          'ffber01' => '100',
        }
    }

    ff_gln_gw::bird6::ebgp::setup { 'ham02': mesh_code => "ffgt" }

    ff_gln_gw::bird4::ebgp::setup { 'ham02': mesh_code => "ffgt" }

    ff_gln_gw::bird6::ebgp_filtered {
      'ham02':
        gre_yaml => "ebgp_ham02.yaml",
        mesh_code => "ham02",
        sitelocal_prefix => "2a06:e881:1702::/48, 2a06:e881:1700::/48, 2a06:e881:260c::/48, 2a06:e881:1705::/48, 2a06:e881:1708::/48, 2a06:e881:1701::/48",
        no_export_prefix => "2a06:e881:1700::/44{44,48}, 2a06:e881:2600::/44{44,48}, 2001:678:2c0::/48, 2001:678:2b8::/48, 2001:678:2b9::/48, 2a07:a907:50c::/48",
    }

    ff_gln_gw::bird4::ebgp_filtered {
      'ham02':
        gre_yaml => "ebgp_ham02.yaml",
        mesh_code => "ham02",
        #sitelocal_prefix => "193.34.79.0/24, 193.26.120.0/24",
        #no_export_prefix => "192.251.226.0/24",
    }

    ff_gln_gw::bird6::local { "ffgt_local": }

    ff_gln_gw::bird4::local { "ffgt_local": }

    root@chimaera:~#
