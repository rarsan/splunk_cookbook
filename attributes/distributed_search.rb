# Enable/Disable Distributed Search
# 1-n search heads <-> 1-n indexers
# See http://docs.splunk.com/Documentation/Splunk/latest/Deploy/Whatisdistributedsearch
default['splunk']['distributed_search']          = false

# The IP of the dedicated search master
default['splunk']['dedicated_license_master']    = ""

# Designate node as dedicated license master - will ignore above IP attribute
default['splunk']['is_dedicated_license_master'] = false