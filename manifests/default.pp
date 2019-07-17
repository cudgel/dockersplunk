class { 'splunk':
  type              => 'standalone',
  create_user       => true,
  version           => '7.2.5.1',
  release           => '962d9a8e1586',
}

