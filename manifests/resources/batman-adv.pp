class ff_gln_gw::resources::batman-adv () {
  include ff_gln_gw::resources::repos

  Class[ff_gln_gw::resources::repos]
  -> 
  package { 
    'batctl': ensure => '2013.4.0-1'; # installed;
    'batman-adv-dkms': ensure => installed;
  }
}
