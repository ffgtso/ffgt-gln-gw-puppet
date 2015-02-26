class ffgt_gln_gw::resources::batman-adv () {
  include ffgt_gln_gw::resources::repos

  Class[ffgt_gln_gw::resources::repos]
  -> 
  package { 
    'batctl': ensure => installed;
    'batman-adv-dkms': ensure => installed;
  }
}
