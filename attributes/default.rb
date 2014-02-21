default['splunk']['db_directory']                 = '/volr/splunk'
default['splunk']['auth']                         = 'admin:SomePassword123'
default['splunk']['install_type']                 = 'server'
default['splunk']['receiver_port']                = 9997

default['splunk']['configs']['server']            = ['inputs']
default['splunk']['configs']['forwarder']         = ['outputs']
default['splunk']['env_configs']['server']        = %w{props transforms}
default['splunk']['env_configs']['forwarder']     = ['forwarder_inputs']

default['splunk']['env']                          = 'prodlike'
default['splunk']['indexers']                     = []

default['splunk']['distributed_search']           = false
default['splunk']['dedicated_indexer']            = false

default['splunk']['use_license_master']           = false
default['splunk']['license_master']               = '127.0.0.1' # license master IP

default['splunk']['deploy_dashboards']            = false
default['splunk']['dashboards']                   = [] # array of dashboards

default['splunk']['scripted_auth']                = false
default['splunk']['scripted_auth_directory']      = 'etc/system/scripted_auth'
default['splunk']['scripted_auth_script']         = '' # main auth script
default['splunk']['scripted_auth_files']          = [] # files located under files/default/scripted_auth
default['splunk']['scripted_auth_templates']      = [] # files under templates/default/scripted_auth

default['splunk']['scripted_auth_data_bag_group'] = 'data_bag_group'
default['splunk']['scripted_auth_data_bag_name']  = 'data_bag_name'
default['splunk']['data_bag_key']                 = 'data_bag_secret'

# Use SSL for the web interface
default['splunk']['web_ssl']    = true

default['splunk']['ssl_crt'] = 'ssl.crt'
default['splunk']['ssl_key'] = 'ssl.key'

default['splunk']['server_role']   = 'splunk-server-role' # role cookbook or role name for the server
default['splunk']['root_endpoint'] = '/'

default['splunk']['search_head_pool_directory'] = '/opt/splunk_shared_bundles' # for splunk shared bundles
