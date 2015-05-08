define duplicity::job(
  $ensure = 'present',
  $spoolfile,
  $directory = undef,
  $bucket = undef,
  $dest_id = undef,
  $dest_key = undef,
  $folder = undef,
  $cloud = undef,
  $encrypt_key_id = undef,
  $encrypt_key_passphrase = undef,
  $pubkey_id = undef,
  $swift_authurl = undef,
  $swift_authversion = '2',
  $full_if_older_than = undef,
  $pre_command = undef,
  $remove_older_than = undef,
  $sign_key_id = undef,
  $sign_key_passphrase = undef,
  $custom_endpoint = undef,
  $archive_directory = '~/.cache/duplicity/',
) {

  include duplicity::params
  include duplicity::packages

  if $pubkey_id != undef and encrypt_key_id == undef {
    $encrypt_key_id = $pubkey_id
    warning('pubkey_id is depreciated - please use encrypt_key_id')
  }

  $_bucket = $bucket ? {
    undef   => $duplicity::params::bucket,
    default => $bucket
  }

  $_dest_id = $dest_id ? {
    undef   => $duplicity::params::dest_id,
    default => $dest_id
  }

  $_dest_key = $dest_key ? {
    undef   => $duplicity::params::dest_key,
    default => $dest_key
  }

  $_folder = $folder ? {
    undef   => $duplicity::params::folder,
    default => $folder
  }

  $_cloud = $cloud ? {
    undef   => $duplicity::params::cloud,
    default => $cloud
  }

  $_encrypt_key_id = $encrypt_key_id ? {
    undef   => $duplicity::params::encrypt_key_id,
    default => $encrypt_key_id
  }

  $_sign_key_id = $sign_key_id ? {
    undef   => $duplicity::params::sign_key_id,
    default => $sign_key_id
  }

  $_hour = $hour ? {
    undef   => $duplicity::params::hour,
    default => $hour
  }

  $_minute = $minute ? {
    undef   => $duplicity::params::minute,
    default => $minute
  }

  $_full_if_older_than = $full_if_older_than ? {
    undef   => $duplicity::params::full_if_older_than,
    default => $full_if_older_than
  }

  $_pre_command = $pre_command ? {
    undef   => '',
    default => "$pre_command && "
  }

  $_encryption = $_encrypt_key_id ? {
    undef   => '--no-encryption',
    default => "--encrypt-key ${_encrypt_key_id}"
  }

  $_signing = $sign_key_id ? {
    undef   => '',
    default => "--sign-key ${_sign_key_id}"
  }

  $_remove_older_than = $remove_older_than ? {
    undef   => $duplicity::params::remove_older_than,
    default => $remove_older_than,
  }

  if !($_cloud in [ 's3', 'cf', 'swift', 'file' ]) {
    fail('$cloud required and at this time supports s3 for amazon s3 and cf for Rackspace cloud files')
  }

  case $ensure {
    'present' : {

      if !$directory {
        fail('directory parameter has to be passed if ensure != absent')
      }

      if !$_bucket and !$custom_endpoint {
        fail('You need to define a container/bucket name!')
      }

    }

    'absent' : {
    }
    default : {
      fail('ensure parameter must be absent or present')
    }
  }

  $_environment = $_cloud ? {
    'cf'    => ["CLOUDFILES_USERNAME='${_dest_id}'", "CLOUDFILES_APIKEY='${_dest_key}'"],
    's3'    => ["AWS_ACCESS_KEY_ID='${_dest_id}'", "AWS_SECRET_ACCESS_KEY='${_dest_key}'"],
    'swift' => ["SWIFT_AUTHURL='${swift_authurl}'", "SWIFT_AUTHVERSION='${swift_authversion}'", "SWIFT_PASSWORD='${_dest_key}'", "SWIFT_USERNAME='${_dest_id}'"],
    'file'  => [],
  }

  if $custom_endpoint {
    $_target_url = $custom_endpoint
  }
  else {
    $_target_url = $_cloud ? {
    'cf'     => "'cf+http://${_bucket}'",
    's3'     => "'s3+http://${_bucket}/${_folder}/${name}/'",
    'file'   => "'file://${_bucket}'",
    'swift'  => "'swift://${_bucket}'",
    }
  }

  $_remove_older_than_command = $_remove_older_than ? {
    undef   => '',
    default => "duplicity remove-older-than ${_remove_older_than} --s3-use-new-style ${_encryption} ${_signing} --force ${_target_url}"
  }

  file { $spoolfile:
    ensure  => $ensure,
    content => template('duplicity/file-backup.sh.erb'),
    owner   => 'root',
    mode    => '0700',
  }

  if $_encrypt_key_id {
    exec { "duplicity-pgp-encrypt_${_target_url}":
      command => "gpg --keyserver subkeys.pgp.net --recv-keys ${_encrypt_key_id}",
      path    => '/usr/bin:/usr/sbin:/bin',
      unless  => "gpg --list-key ${_encrypt_key_id}"
    }
  }

  if $_sign_key_id {
    exec { "duplicity-pgp-sign_${_target_url}":
      command => "gpg --keyserver subkeys.pgp.net --recv-keys ${_sign_key_id}",
      path    => '/usr/bin:/usr/sbin:/bin',
      unless  => "gpg --list-key ${_sign_key_id}"
    }
  }

}
