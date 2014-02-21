include_attribute 'splunk::default'
##################
# SERVER CONFIGS #
##################

######################
# alert_actions.conf #
######################
default['splunk']['conf']['server']['alert_actions'] = {
  'email' => {
    'from' => 'splunk-noreply@mydomain.com',
    'hostname' => 'mydomain.com',
    'reportServerEnabled' => '0'
  }
}

############
# web.conf #
############
default['splunk']['conf']['server']['web'] = {
  'settings' => {
    'startwebserver' =>  (node['splunk']['distributed_search'] && !node['splunk']['dedicated_indexer']) || !node['splunk']['distributed_search'] ? '1' : '0',
    'httpport' => '443',
    'enableSplunkWebSSL' => node['splunk']['web_ssl'],
    'ui_inactivity_timeout' => '0',
    'minify_js' => true,
    'minify_css' => true,
    'root_endpoint' => node['splunk']['root_endpoint']
  }
}

default['splunk']['conf']['server']['web']['settings']['privKeyPath'] = "ssl/#{node['splunk']['ssk_key']}" if node['splunk']['web_ssl']
default['splunk']['conf']['server']['web']['settings']['caCertPath'] = "ssl/#{node['splunk']['ssk_key']}" if node['splunk']['web_ssl']

################
# indexes.conf #
################
default['splunk']['conf']['server']['indexes'] = {
  'main' => {
    'homePath' => '$SPLUNK_DB/defaultdb/db',
    'coldPath' => '$SPLUNK_DB/defaultdb/colddb',
    'thawedPath' => '$SPLUNK_DB/defaultdb/thaweddb',
    'coldToFrozenDir' => '$SPLUNK_DB/defaultdb/frozendb',
    # Max data size of a bucket.  Moved from hot to warm after this.
    'maxDataSize' => '',
     # Max number of warm db's.  Moved to cold after this number
    'maxWarmDBCount' => '',
    # Number of seconds before data is moved from either warm/cold to frozen
    'frozenTimePeriodInSecs' => '7889227', # 3 months
    # Max size of the entire (hot/warm/cold).
    # Once reached, data will be frozen if a coldToFrozenDir option is defined
    'maxTotalDataSizeMB' => '7864320' # 7.5TB
  }
}

#######################
# Default search time #
#######################
default['splunk']['conf']['server']['ui-prefs'] = {
  'dispatch.earliest_time' => '-1h',
  'dispatch.latest_time' => 'now',
  'display.page.search.mode' => 'fast'
}

#####################
# FORWARDER CONFIGS #
#####################
default['splunk']['conf']['forwarder']['limits'] = {
  'thruput' => {
    'maxKBps' => '0'
  },
  'inputproc' => {
    'max_fd' => '1024'
  }
}
