# Clustering
# See http://docs.splunk.com/Documentation/Splunk/latest/Indexer/Aboutclusters
default['splunk']['cluster_deployment']  = false

# Clustering replication factor
default['splunk']['replication_factor']  = 3
# Clustering search factor
default['splunk']['search_factor']       = 2

# Set default secret key for communication authentication
default['splunk']['pass4SymmKey']        = "password"

# Peer replication port
default['splunk']['replication_port']    = "9887"