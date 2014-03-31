# Name of the cookbook (referenced in forwarder.rb)
default['splunk']['cookbook_name']             = "splunk"

# Directories
default['splunk']['server_home']               = "/opt/splunk"
default['splunk']['db_directory']              = "/volr/splunk"

# Web config
default['splunk']['web_server_port']           = "80" # Change to 443/other if you're doing ssl
default['splunk']['mgmt_server_port']          = "8089"
default['splunk']['root_endpoint']             = "/" # Web Endpoint
default['splunk']['browser_timeout']           = "0"
default['splunk']['minify_js']                 = "true"
default['splunk']['minify_css']                = "true"

default['splunk']['use_ssl']                   = false
default['splunk']['ssl_crt']                   = "ssl.crt"
default['splunk']['ssl_key']                   = "ssl.key"

# License path
default['splunk']['license_path']              = ""
# The IP of the dedicated license master
default['splunk']['license_master']            = ""
# Designate node as dedicated license master (will ignore license_master attribute if any)
default['splunk']['is_license_master']         = false

# Dashboards to deploy
default['splunk']['deploy_dashboards']         = true
default['splunk']['dashboards_to_deploy']      = ["apache_http","useragents"]

default['splunk']['server_config_folder']      = "prodlike"

# Static Server Configs (Configs that match regardless of environment -Dev,QA,PL,Prod,Etc)
default['splunk']['static_server_configs']     = ["web","transforms","limits","indexes","server"]

# Dynamic Server Configs (Configs that change per environment)
default['splunk']['dynamic_server_configs']    = ["inputs","props"]

# Configuration values for forwarders
default['splunk']['receiver_port']             = "9997"

# Change the default admin password (Username::Password)
default['splunk']['auth']                      = "admin:changeme"

# Set the role of your splunk server/dedicated search head
default['splunk']['server_role']               = "splunk-server"
# Needed for distributed search.  This is assigned to the indexers.
default['splunk']['indexer_role']              = "splunk-indexer"
# Role for cluster search head
default['splunk']['cluster_search_role']       = 'cluster-search-head'
# Role for cluster master node
default['splunk']['cluster_master_role']       = 'cluster-master'
# Role for cluster peer node
default['splunk']['cluster_indexer_role']      = 'cluster-peer'

# limits.conf 
default['splunk']['max_searches_per_cpu']      = 4