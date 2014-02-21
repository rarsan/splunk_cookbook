# rubocop:disable SymbolName
include SplunkHelpers

use_inline_resources if defined?(use_inline_resources)

action :install do
  @install_type = @new_resource.install_type
  @base_dir = splunk_home(@install_type)
  @distributed_search = @new_resource.distributed_search
  @scripted_auth = @new_resource.scripted_auth
  @dedicated_indexer = node['splunk']['dedicated_indexer']
  @search_pooling = node['splunk']['search_head_pooling']
  @configs = configs_to_deploy(@distributed_search, @scripted_auth, @dedicated_indexer) | node['splunk']['configs'][@install_type]
  @chef_solo = Chef::Config[:solo]

  # Syntax is this way only because of FC0003
  if Chef::Config[:solo]
    Chef::Log.warn("\n\n***\nDistributed Search will not work with Chef Solo because we depend on Chef Search\n***\n\n") if @distributed_search
  else
    @search_heads = search(:node, "role:#{node['splunk']['server_role']} OR recipe:*#{node['splunk']['server_role']}* OR recipe:*boc-splunk-role*") if @distributed_search
  end

  download_and_install(
    node['splunk']['version'],
    node['splunk']['build'],
    @install_type
  )

  base_files
  base_configs
  env_configs
  forwarding_ssl_certs if @new_resource.ssl_forwarding

  if @install_type == 'server'
    web_ssl_certs if @new_resource.web_ssl
    scripted_auth if @scripted_auth && !@dedicated_indexer
    deploy_dashboards if @new_resource.deploy_dashboards
    link_to_master if @new_resource.use_license_master
    distributed_search_configs if @distributed_search
    enabled_search_pooling if @distributed_search && !@dedicated_indexer
  end

  service 'splunk' do
    action [:enable, :start]
    supports :start => true, :stop => true, :restart => true, :status => true
  end
end

private

def base_files
  base_dir = @base_dir
  dedicated_indexer = @dedicated_indexer
  distributed_search = @distributed_search
  install_type = @install_type

  template "#{base_dir}/etc/splunk-launch.conf" do
    source 'common/splunk-launch.conf.erb'
    mode '0640'
    owner 'root'
    group 'root'
    variables(:base_dir => base_dir)
    only_if { install_type == 'server' }
  end

  execute "#{base_dir}/bin/splunk enable boot-start --accept-license --answer-yes" do
    not_if do
      ::File.symlink?('/etc/rc3.d/S90splunk')
    end
  end

  template '/etc/init.d/splunk' do
    source 'common/splunk.erb'
    mode '0755'
    owner 'root'
    group 'root'
    variables(:base_dir => base_dir)
  end

  splunk_password = node['splunk']['auth'].split(':')[1]
  execute "#{base_dir}/bin/splunk edit user admin -password #{splunk_password} -roles admin -auth admin:changeme && echo true > /opt/splunk_setup_passwd" do
    not_if do
      ::File.exists?('/opt/splunk_setup_passwd')
    end
  end

  execute "#{base_dir}/bin/splunk enable listen #{node['splunk']['receiver_port']} -auth #{node['splunk']['auth']}" do
    not_if "grep #{node['splunk']['receiver_port']} #{base_dir}/etc/system/local/inputs.conf"
    only_if do
      (dedicated_indexer == true || distributed_search == false) && install_type == 'server'
    end
  end
end

def base_configs
  base_dir = @base_dir
  dedicated_indexer = @dedicated_indexer
  search_heads = @search_heads
  install_type = @install_type

  unless node['splunk']['conf'][install_type].nil?
    node['splunk']['conf'][install_type].each_key do |cfg|
      template "#{base_dir}/etc/system/local/#{cfg}.conf" do
        source 'common/config.conf.erb'
        owner 'root'
        group 'root'
        mode '0640'
        variables(:base => node['splunk']['conf'][install_type][cfg])
        only_if { node['splunk']['conf'][install_type][cfg] }
        notifies :restart, 'service[splunk]'
      end
    end
  end

  @configs.each do |config|
    template "#{base_dir}/etc/system/local/#{config}.conf" do
      source "common/#{config}.conf.erb"
      owner 'root'
      group 'root'
      mode '0640'
      variables(
        :base_dir => base_dir,
        :dedicated_indexer => dedicated_indexer,
        :search_heads => search_heads,
        :ec2_support => ec2_support,
        :indexers => node['splunk']['indexers']
      )
      notifies :restart, 'service[splunk]'
    end
  end
end

def deploy_dashboards
  directory "#{@base_dir}/etc/users/admin/search/local/data/ui/views" do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end

  node['splunk']['dashboards'].each do |dashboard|
    cookbook_file "#{@base_dir}/etc/users/admin/search/local/data/ui/views/#{dashboard}.xml" do
      source "dashboards/#{dashboard}.xml"
    end
  end
end

def distributed_search_configs # rubocop:disable CyclomaticComplexity
  unless @chef_solo
    if @dedicated_indexer
      # We need to get the search heads
      @search_heads.each do |server|
        unless server['splunk'].nil? || server['splunk']['trustedPem'].nil? || server['splunk']['splunkServerName'].nil?
          directory "#{@base_dir}/etc/auth/distServerKeys/#{server['splunk']['splunkServerName']}" do
            owner 'root'
            group 'root'
            action :create
          end

          file "#{@base_dir}/etc/auth/distServerKeys/#{server['splunk']['splunkServerName']}/trusted.pem" do
            owner 'root'
            group 'root'
            mode '0600'
            content server['splunk']['trustedPem'].strip
            action :create
            notifies :restart, 'service[splunk]'
          end
        end
      end
    else
      # splunk_server_name = `grep -m 1 'serverName = ' #{@base_dir}/etc/system/local/server.conf | sed 's/serverName = //'`
      get_server_name = Mixlib::ShellOut.new("grep -m 1 'serverName = ' #{@base_dir}/etc/system/local/server.conf | sed 's/serverName = //'")
      get_server_name.run_command
      get_server_name.error!

      splunk_server_name = get_server_name.stdout.strip

      if ::File.exists?("#{@base_dir}/etc/auth/distServerKeys/trusted.pem")
        trusted_pem = IO.read("#{@base_dir}/etc/auth/distServerKeys/trusted.pem")
        node.normal['splunk']['trustedPem'] = trusted_pem if node['splunk']['trustedPem'].nil? || node['splunk']['trustedPem'] != trusted_pem
        node.normal['splunk']['splunkServerName'] = splunk_server_name if node['splunk']['splunkServerName'].nil? || node['splunk']['splunkServerName'] != splunk_server_name
      end
    end
  end
end

def download_and_install(version, build, install_type) # rubocop:disable ParameterLists
  splunk_package = package_name(version, build, install_type)
  source_url = package_url(node['splunk']['server_root'], version, splunk_package, install_type)

  remote_file "#{Chef::Config['file_cache_path']}/#{splunk_package}" do
    source source_url
    action :create_if_missing
  end

  package splunk_package do
    source "#{Chef::Config['file_cache_path']}/#{splunk_package}"
    case node['platform']
    when 'centos', 'redhat', 'fedora', 'amazon', 'scientific'
      provider Chef::Provider::Package::Rpm
    when 'debian', 'ubuntu'
      provider Chef::Provider::Package::Dpkg
      new_resource.updated_by_last_action(true)
    end
    action :install
  end
end

def enabled_search_pooling
  base_dir = @base_dir

  # In order to setup search head pooling, splunk must be stopped
  execute "#{base_dir}/bin/splunk stop" do
    not_if "grep \"storage = #{node['splunk']['search_head_pool_directory']}\" #{base_dir}/etc/system/local/server.conf"
    returns [0, 1]
  end

  execute 'Enabling Search Head Pooling' do
    command "#{base_dir}/bin/splunk pooling enable #{node['splunk']['search_head_pool_directory']}"
    not_if "grep \"storage = #{node['splunk']['search_head_pool_directory']}\" #{base_dir}/etc/system/local/server.conf"
    notifies :restart, 'service[splunk]'
  end
end

def env_configs
  base_dir = @base_dir

  node['splunk']['env_configs'][@install_type].each do |cfg|
    template "#{@base_dir}/etc/system/local/#{cfg.split('forwarder_').pop}.conf" do
      source "#{node['splunk']['env']}/#{cfg}.conf.erb"
      owner 'root'
      group 'root'
      mode '0640'
      variables(
        :base_dir => base_dir,
        :cloud_support => cloud_support,
        :ec2_support => ec2_support
      )
      notifies :restart, 'service[splunk]'
    end
  end
end

def forwarding_ssl_certs # rubocop:disable CyclomaticComplexity
  directory "#{@base_dir}/etc/auth/forwarders" do
    owner 'root'
    group 'root'
    action :create
  end

  [node['splunk']['ssl_forwarding_cacert'], node['splunk']['ssl_forwarding_servercert']].each do |cert|
    cookbook_file "#{@base_dir}/etc/auth/forwarders/#{cert}" do
      source "ssl/forwarders/#{cert}"
      owner 'root'
      group 'root'
      mode '0755'
      notifies :restart, 'service[splunk]'
    end
  end

  if ::File.exists?("#{@base_dir}/etc/system/local/inputs.conf")
    # inputs_pass = `grep -m 1 'password = ' #{@base_dir}/etc/system/local/inputs.conf | sed 's/password = //'`
    inputs_pass = Mixlib::ShellOut.new("grep -m 1 'password = ' #{@base_dir}/etc/system/local/inputs.conf | sed 's/password = //'")
    inputs_pass.run_command
    inputs_pass.error!

    node.normal['splunk']['inputsSSLPass'] = inputs_pass.stdout if
      inputs_pass.stdout.match(/^\$1\$/) && inputs_pass.stdout != node['splunk']['inputsSSLPass']
  end

  if ::File.exists?("#{@base_dir}/etc/system/local/outputs.conf")
    # outputs_pass = `grep -m 1 'sslPassword = ' #{@base_dir}/etc/system/local/outputs.conf | sed 's/sslPassword = //'`
    outputs_pass = Mixlib::ShellOut.new("grep -m 1 'sslPassword = ' #{@base_dir}/etc/system/local/outputs.conf | sed 's/sslPassword = //'")
    outputs_pass.run_command
    outputs_pass.error!

    node.normal['splunk']['outputsSSLPass'] = outputs_pass.stdout if
      outputs_pass.stdout.match(/^\$1\$/) && outputs_pass.stdout != node['splunk']['outputsSSLPass']
  end
end

def link_to_master
  base_dir = @base_dir
  # ipaddress = cloud_support ? node['cloud']['public_ipv4'] : node['ipaddress'] # not actually used...
  execute 'Linking license to search master' do
    command "#{base_dir}/bin/splunk edit licenser-localslave -master_uri 'https://#{node['splunk']['license_master']}:8089' -auth #{node['splunk']['auth']}"
    not_if "grep \"master_uri = https://#{node['splunk']['license_master']}:8089\" #{base_dir}/etc/system/local/server.conf"
  end
end

def scripted_auth
  scripted_auth_creds = Chef::EncryptedDataBagItem.load(
    node['splunk']['scripted_auth_data_bag_group'],
    node['splunk']['scripted_auth_data_bag_name'],
    node['splunk']['data_bag_key']
  )

  directory "#{@base_dir}/#{node['splunk']['scripted_auth_directory']}" do
    recursive true
    action :create
  end

  node['splunk']['scripted_auth_files'].each do |auth_file|
    cookbook_file "#{@base_dir}/#{node['splunk']['scripted_auth_directory']}/#{auth_file}" do
      source "scripted_auth/#{auth_file}"
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
  end

  node['splunk']['scripted_auth_templates'].each do |auth_templ|
    template "#{@base_dir}/#{node['splunk']['scripted_auth_directory']}/#{auth_templ}" do
      source "scripted_auth/#{auth_templ}.erb"
      owner 'root'
      group 'root'
      mode '0744'
      variables(
        :user => scripted_auth_creds['user'],
        :password => scripted_auth_creds['password']
      )
    end
  end
end

def web_ssl_certs
  directory "#{@base_dir}/ssl" do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
    recursive true
  end

  cookbook_file "#{@base_dir}/ssl/#{node['splunk']['ssl_crt']}" do
    source "ssl/#{node['splunk']['ssl_crt']}"
    mode '0755'
    owner 'root'
    group 'root'
  end

  cookbook_file "#{@base_dir}/ssl/#{node['splunk']['ssl_key']}" do
    source "ssl/#{node['splunk']['ssl_key']}"
    mode '0755'
    owner 'root'
    group 'root'
  end
end
