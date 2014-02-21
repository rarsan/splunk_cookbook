default['splunk']['apps'] = {
  'splunk_deployment_monitor' => {
    'checksum' => 'shasum_of_file',
    'dependencies' => [],
    'file' => 'url_to_download',
    'remote_download' => true,
    'templates' => [],
    'version' => '5.0.3'
  },
  'sos' => {
    'checksum' => 'shasum_of_file',
    'dependencies' => [],
    'file' => 'url_to_download',
    'remote_download' => true,
    'templates' => [],
    'version' => '3.1.0'
  }
}
