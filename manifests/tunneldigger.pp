class ff_gln_gw::tunneldigger(
  $install_dir='/srv/tunneldigger/tunneldigger',
  $revision='master',
  $virtualenv="/srv/tunneldigger/env_tunneldigger",
  $address,
  $port='53,123,8942',
  $interface,
  $max_tunnels='1024',
  $port_base='10001',
  $tunnel_id_base='100',
  $namespace='mesh',
  $connection_rate_limit='10',
  $pmtu='0',
  $verbosity='DEBUG',
  $log_ip_addresses='true',
  $templates_dir='tunneldigger',
  $functions='',
  $session_up='setup_interface.sh',
  $session_pre_down='teardown_interface.sh',
  $session_down='',
  $session_mtu_changed='',
  $bridge_mac,
  $bridge_mtu='1364',
  $systemd='1',
  $mesh_code
) {

  class { 'python':
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
    gunicorn   => 'absent',
  }

  package { [
    'iproute',
    'git',
    'libnetfilter-conntrack-dev',
    'libnfnetlink-dev',
    'libffi-dev',
    'libevent-dev',
    'ebtables'
  ]:
    ensure => present,
  }

  vcsrepo { $install_dir:
    ensure   => present,
    provider => git,
    source   => 'https://github.com/wlanslovenija/tunneldigger.git',
    revision => $revision,
    require  => [
      Package['git']
    ]
  }

  python::virtualenv { $virtualenv:
    ensure       => present,
    notify       => Exec['setup']
  }

  exec { 'setup':
    command => "${virtualenv}/bin/python setup.py install",
    path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
    cwd => "${install_dir}/broker",
  }

  file {
    "/etc/network/interfaces.d/${mesh_code}-tunneldigger.cfg":
      ensure => file,
      content => template('ff_gln_gw/etc/network/tunneldigger-bridge.erb');
  } ->
  exec {
    "start_td_bridge_interface_${mesh_code}":
      command => "/sbin/ifup br-tdig-${mesh_code}",
      unless  => "/bin/ip link show dev br-tdig-${mesh_code} 2> /dev/null",
      before  => Ff_gln_gw::Monitor::Vnstat::Device["br-tdig-${mesh_code}"],
      require => [ File_Line["/etc/iproute2/rt_tables"]
                 , Class[ff_gln_gw::resources::sysctl]
                 ];
  } ->
  ff_gln_gw::firewall::device { "br-tdig-${mesh_code}":
    chain => "mesh"
  } ->
  ff_gln_gw::firewall::forward { "br-tdig-${mesh_code}":
    chain => "mesh"
  }

  file { "${install_dir}/broker/l2tp_broker.cfg":
    ensure    => file,
    content   => template('ff_gln_gw/tunneldigger/l2tp_broker.cfg.erb'),
    require   => Exec['setup'],
  }

  $scripts = "${install_dir}/broker/scripts"

  #if $functions {
  #  file { "${scripts}/${functions}":
  #    ensure    => file,
  #    content   => template("ff_gln_gw/${templates_dir}/${functions}.erb"),
  #    require   => Exec['setup'],
  #  }
  #}

  if $session_up {
    file { "${scripts}/${session_up}":
      ensure    => file,
      content   => template("ff_gln_gw/${templates_dir}/${session_up}.erb"),
      require   => Exec['setup'],
    }
  }

  if $session_pre_down {
    file { "${scripts}/${session_pre_down}":
      ensure    => file,
      content   => template("ff_gln_gw/${templates_dir}/${session_pre_down}.erb"),
      mode      => '744',
      require   => Exec['setup'],
    }
  }

  if $session_down != '' {
    file { "${scripts}/${session_down}":
      ensure    => file,
      content   => template("ff_gln_gw/${templates_dir}/${session_down}.erb"),
      mode      => '744',
      require   => Exec['setup'],
    }
  }

  if $session_mtu_changed != '' {
    file { "${scripts}/${session_mtu_changed}":
      ensure    => file,
      content   => template("ff_gln_gw/${templates_dir}/${session_mtu_changed}.erb"),
      mode      => '744',
      require   => Exec['setup'],
    }
  }

  file { "${install_dir}/broker/scripts/tunneldigger-broker":
    ensure    => file,
    content   => template('ff_gln_gw/tunneldigger/tunneldigger-broker.erb'),
    require   => Exec['setup'],
  }

  if $systemd == '1' {
    file { '/etc/systemd/system/tunneldigger.service':
      ensure    => file,
      content   => template('ff_gln_gw/tunneldigger/tunneldigger.service.erb'),
      require   => Exec['setup'],
      notify    => Service['tunneldigger'],
    }
  }

  service { "tunneldigger":
    ensure      => 'running',
    enable      => 'true',
  }

  file { '/etc/modules-load.d/tunneldigger.conf':
    ensure      => file,
    content     => template('ff_gln_gw/tunneldigger/modules.conf.erb'),
    require     => Exec['setup'],
  }

}
