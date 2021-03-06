define duplicity(
  $ensure = 'present',
  $directory = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $swift_authurl = undef,
  $swift_authversion = '2',
  $folder = undef,
  $cloud = undef,
  $encrypt_key_id = undef,
  $encrypt_key_passphrase = undef,
  $pubkey_id = undef,
  $hour = undef,
  $minute = undef,
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
  $sign_key_id = undef,
  $sign_key_passphrase = undef,
  $custom_endpoint = undef,
  $create_cron = true,
  $script_owner = 'root',
  $script_permissions = '0700',
  $script_group_owner = 'root',
  ) {

  include duplicity::params
  include duplicity::packages

  $spoolfile = "${duplicity::params::job_spool}/${name}.sh"

  if $pubkey_id != undef and $encrypt_key_id == undef {
    $encrypt_key_id = $pubkey_id
    warning('pubkey_id is depreciated - please use encrypt_key_id')
  }

  duplicity::job { $name :
    ensure                 => $ensure,
    spoolfile              => $spoolfile,
    script_owner           => $script_owner,
    script_permissions     => $script_permissions,
    script_group_owner     => $script_group_owner,
    directory              => $directory,
    bucket                 => $bucket,
    dest_id                => $dest_id,
    dest_key               => $dest_key,
    folder                 => $folder,
    cloud                  => $cloud,
    encrypt_key_id         => $encrypt_key_id,
    encrypt_key_passphrase => $encrypt_key_passphrase,
    swift_authurl          => $swift_authurl,
    swift_authversion      => $swift_authversion,
    full_if_older_than     => $full_if_older_than,
    pre_command            => $pre_command,
    remove_older_than      => $remove_older_than,
    sign_key_id            => $sign_key_id,
    sign_key_passphrase    => $sign_key_passphrase,
    custom_endpoint        => $custom_endpoint,
  }

  $_hour = $hour ? {
    undef   => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef   => $duplicity::params::minute,
    default => $minute
  }

  if $create_cron {
    cron { $name :
      ensure  => $ensure,
      command => $spoolfile,
      user    => 'root',
      minute  => $_minute,
      hour    => $_hour,
    }

  File[$spoolfile]->Cron[$name]

  }

}
