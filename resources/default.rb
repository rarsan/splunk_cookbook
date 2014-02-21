actions :install

default_action :install

attribute :name, :kind_of => String, :name_attribute => true
attribute :deploy_dashboards, :kind_of => [TrueClass, FalseClass]
attribute :distributed_search, :kind_of => [TrueClass, FalseClass]
attribute :install_type, :kind_of => String
attribute :scripted_auth, :kind_of => [TrueClass, FalseClass]
attribute :ssl_forwarding, :kind_of => [TrueClass, FalseClass]
attribute :use_license_master, :kind_of => [TrueClass, FalseClass]
attribute :web_ssl, :kind_of => [TrueClass, FalseClass]
