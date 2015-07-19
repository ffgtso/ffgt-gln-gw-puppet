# Freifunk (Gütersloh) Gluon Gateway Module

Based on https://github.com/ffnord/ffnord-puppet-gateway --
forked due to different goals; while the aim is "works for us"
initially, any bugfixes, additions etc. to make this a complete
module to puppetize a Freifunk Gluon Gateway from scratch are
more then welcome.

Definition of done: run "puppet apply --verbose /root/gateway.pp",
this should setup a working Gluon Gateway with the selected options
(IC-VPN, IPv4-exit via OpenVPN/GRE/locally, ...) for the configured
communitiy/communities, usable after a reboot.

It's considered a replacement for the plenty Wiki pages out there
on how to do that, but in a automated, repeatable way (hence the
use of puppet). Please note that puppet is only to be run once (or
maybe on major updates to the code), NOT constantly. Hence all
volatile data, e. g. from git repositories, need to be fetched
via cronjobs, which puppet should set up for you. puppet is used
to boot-strap your system, NOT to keep it in shape, at least not
in terms of the Gluon Gateway functionality.

As stated, credits to get this going in the first place go to
the FFNord people, which started their work as "a complete rewrite
of the puppet scripts provided by the Freifunk Hamburg Community".



The 'ff_gln_gw::mesh' block will setup a bridge, fastd, batman,
ntp, dhcpd, dns (bind9), radvd, bird, bird6 and firewall rules for
IPv4 and IPv6.
There are types for setting up monitoring, icvpn, anonymous vpn,
local exit and alfred announcements.

## Open Problems

* As usual, you should have configure the fully qualified domain name (fqdn) before running
  this module, you can check this with 'hostname -f'.
* The configured dns server only provide support for the root zone.
  Custom tlds are currently not supported.  
* Bird6 must be reconfigured after a puppet run, otherwise the icvpn protocols are not available
* When touching the network devices on a rerun named should be restarted.

## TODO

* Bird IPv4 Route exchange
* Apply firewall rules automatially, when all rules are defined.

## Usage

Install as a puppet module, then include with node-specific parameters.

### Dependencies

Install Puppet and some required modules with:

```
apt-get install --no-install-recommends puppet git
puppet module install puppetlabs-stdlib
puppet module install puppetlabs-apt
puppet module install puppetlabs-vcsrepo
puppet module install saz-sudo
puppet module install torrancew-account
```

Then add this module (which is not in the puppet forge, so it has to be
downloaded manually):

```
cd /etc/puppet/modules
git clone https://github.com/ffgtso/ffgt-gln-gw-puppet.git ff_gln_gw
```

### Parameters

Now include the module in your manifest and provide all parameters.
Basically there is one type for mesh network, which pulls
in all the magic and classes for the icvpn connection, monitoring and
anonymous vpn uplink.

Please make sure that the content of your fastd key-file looks like this:
```
secret "<********>";
```
The stars are replaced by your privat fastd key


Example puppet code (save e.g. as `/root/gateway.pp`):

```
# Global parameters for this host
class { 'ff_gln_gw::params':
  router_id => "192.0.0.1", # The id of this router, probably the ipv4 address
                            # of the mesh device of the providing community
  icvpn_as => "64496",      # The as of the providing community (public or private)
  wan_devices => ['eth0']   # A array of devices which should be in the wan zone
  include_dn42_routes => "no",  # yes/no(default) to include routes from DN42
  include_chaos_routes => "no"  # yes/no(default) to include routes from ChaosVPN
}

# You can repeat this mesh block for every community you support
ff_gln_gw::mesh { 'mesh_ffgc':
      mesh_name    => "Freifunk Gotham City",
      mesh_code    => "ffgc",
      mesh_as      => 64496,
      mesh_mac     => "de:ad:be:ef:de:ad",
      mesh_ipv6    => "fd35:f308:a922::ff00/64,
      mesh_ipv4    => "10.35.0.1/19",
      mesh_mtu     => "1426",
      range_ipv4   => "10.35.0.0/16",
      mesh_peerings => "/root/mesh_peerings.yaml",

      fastd_secret => "/root/fastd_secret.key",
      fastd_port   => 10000,
      fastd_peers_git => 'git://somehost/peers.git',
      use_blacklist => "no", # "yes" to use a blacklist approach instead of peer repo
      fastd_bb_git => 'git://somehost/thisgwsbackbone.git',

      dhcp_ranges => [ '10.35.0.2 10.35.0.254'
                     , '10.35.1.1 10.35.1.254'
                     , '10.35.2.2 10.35.2.254'
                     , '10.35.3.2 10.35.3.254'
                     , '10.35.4.2 10.35.4.254'
                     ],
      dns_servers => [ '10.35.5.1'
                     , '10.35.10.1'
                     , '10.35.15.1'
                     , '10.35.20.1'
                     ]
      }

ff_gln_gw::named::zone {
  'ffgc': zone_git => 'git://somehost/ffgc-zone.git';
}

ff_gln_gw::dhcpd::static {
  'ffgc': static_git => 'git://somehost/ffgc-static.git';
}

class {
  'ff_gln_gw::vpn::provider::hideio':
    openvpn_server => "nl-7.hide.io",
    openvpn_port   => 3478,
    openvpn_user   => "wayne",
    openvpn_password => "brucessecretpw",
}

ff_gln_gw::icvpn::setup {
  'gotham_city0':
    icvpn_as => 65035,
    icvpn_ipv4_address => "10.112.0.1",
    icvpn_ipv6_address => "fec0::a:cf:0:35",
    icvpn_exclude_peerings     => [gotham],
    tinc_keyfile       => "/root/tinc_rsa_key.priv"
}

class {
  'ff_gln_gw::monitor::munin':
    host => '10.35.31.1'
}

class {
  'ff_gln_gw::monitor::nrpe':
    allowed_hosts => '10.35.31.1'
}

class { 'ff_gln_gw::alfred': master => true }

class { 'ff_gln_gw::etckeeper': }
```

#### Mesh Type
```
ff_gln_gw :: mesh { '<mesh_code>':
  mesh_name,        # Name of your community, e.g.: Freifunk Gotham City
  mesh_code,        # Code of your community, e.g.: ffgc
  mesh_as,          # AS of your community
  mesh_mac,         # mac address mesh device: 52:54:00:bd:e6:d4
  mesh_ipv6,        # ipv6 address of mesh device in cidr notation, e.g. 10.35.0.1/19
  mesh_mtu,         # mtu used, default only suitable for fastd via ipv4
  range_ipv4,       # ipv4 range allocated to community, this might be different to
                    # the one used in the mesh in cidr notation, e.g. 10.35.0.1/19
  mesh_ipv4,        # ipv4 address of mesh device in cidr notation, e.g. fd35:f308:a922::ff00/64
  mesh_peerings,    # path to the local peerings description yaml file

  fastd_secret,     # fastd secret
  fastd_port,       # fastd port
  fastd_peers_git,  # fastd peers repository

  dhcp_ranges = [], # dhcp pool
  dns_servers = [], # other dns servers in your network
}
```

#### Named Zone Type

This type enables you to receive a zone file from a git repository, include
it into the named configuration and setup a cron job for pulling changes in.
By default the cronjob will pull every 30min. 

The provided configuration should not rely on relative path but use
the absolute path prefixed with '/etc/bind/zones/${name}/'.

```
ff_gln_gw::named::zone {
  '<name>':
     zone_git; # zone file repo
}
```

#### DHCPd static type

This type enables you to receive a file with static dhcp assignments from a git repository, include
it into the dhcp configuration and setup a cron job for pulling changes in.
By default the cronjob will pull every 30min.

The provided configuration should not rely on relative path but use
the absolute path prefixed with '/etc/dhcp/statics/${name}/'.
The name should be the same as the community the static assignments belong to.
There has to be a file named static.conf in the repo.

```
ff_gln_gw::dhcpd::static {
  '<name>':
     static_git; # dhcp static file repo
}
```

#### ICVPN Type

This sets up conenctivity to the IC-VPN with the provided information.

```
ff_gln_gw :: icvpn::setup {
  icvpn_as,            # AS of the community peering
  icvpn_ipv4_address,  # transfer network IPv4 address
  icvpn_ipv6_address,  # transfer network IPv6 address
  icvpn_peerings = [], # Lists of icvpn names

  tinc_keyfile,        # Private Key for tinc
}
```

#### IPv4 Uplink via GRE Tunnel

This is a module for an IPv4 Uplink via GRE tunnel and BGP.
This module and the VPN module are mutually exclusive.
Define the ff_gln_gw::uplink::ip class once and ff_gln_gw::uplink::tunnel
for each tunnel you want to use. See http://wiki.freifunk.net/Freifunk_Hamburg/IPv4Uplink
for a more detailed description.

```
class {
  'ff_gln_gw::uplink::ip':
    nat_network,        # network of IPv4 addresses usable for NAT
    tunnel_network,     # network of tunnel IPs to exclude from NAT
}
ff_gln_gw::uplink::tunnel {
    '<name>':
      local_public_ip,  # local public IPv4 of this gateway
      remote_public_ip, # remote public IPv4 of the tunnel endpoint
      local_ipv4,       # tunnel IPv4 on our side
      remote_ip,        # tunnel IPv4 on the remote side
      remote_as,        # ASN of the BGP server announcing a default route for you
}
```

#### IPv4 Uplink via local exit

This is a module for terminating IPv4 locally. Be sure you know what you are
doing, e. g. run this only outside of Germany or with IPs that are properly
registered to an ISP, or the Störerhaftung will bite you badly.
This module and the VPN and uplink::tunnel modules are mutually exclusive.
Define the ff_gln_gw::uplink::local once well.

```
ff_gln_gw::uplink::local {
    'localexit':
      local_public_ip,  # local public IPv4 of this gateway
      local_net_to_nat  # local network to be NATted to local_public_ip
}
```

#### Peering description

Be aware that currently the own system mesh address will not be filtered.
(This is the mesh_peerings file looked for above.)

```
gc-gw1:
  ipv4: "10.35.5.1"
  ipv6: "fd35:f308:a922::ff01"
gc-gw2:
  ipv4: "10.35.10.1"
  ipv6: "fd35:f308:a922::ff02"
gc-gw3:
  ipv4: "10.35.15.1"
  ipv6: "fd35:f308:a922::ff03"
gc-gw4:
  ipv4: "10.35.20.1"
  ipv6: "fd35:f308:a922::ff04"
```

### Firewall

The firewall rules created are collected in `/etc/iptables.d`, they are not applied
automatically! You have to call `build-firewall` to apply them.

### Run Puppet

To apply the puppet manifest (e.g. saved as `gateway.pp`) run:

```
puppet apply --verbose /root/gateway.pp
build-firewall
```

The verbose flag is optional and shows all changes.
To be even more catious you can also add the `--noop` flag to only show changes
but not apply them.

## Maintenance Mode

To allow administrative operations on a gateway without harming user connections
you should bring the gateway into maintenance mode:

```
maintenance on
```

This will deactivate the gateway feature of batman in the next run of check-gateway.
And after DHCP-Lease-Time there should be no user device with a default route to
the gateway. 

To deactivate maintenance mode and reactivate the batman-adv gateway feature:

```
maintenance off
```

## FASTD Query

For debugging purposes we utilize the status socket of fastd using a little
helper script called `fastd-query`, which itself is a wrapper around ``socat``
and ``jq``. An alias ``fastd-query-${mesh_code}`` is created for every
mesh network. For example you can retrieve the status for some node, where
the node name is equivalent to the peers filename:

```
# fastd-query-ffgc peers name gc-gw0 
```

