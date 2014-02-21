include SplunkHelpers

use_inline_resources if defined?(use_inline_resources)

action :install do

  service 'splunk' do
    action :nothing
    supports :start => true, :stop => true, :restart => true, :status => true
  end

  directory '/opt/splunk/apps_installed' do
    action :create
  end

  unless @new_resource.apps.empty?
    @new_resource.apps.each_pair do |key, val|
      install_app(key, val)
    end
  end
end

def install_app(app_name, settings)
  install_dependencies settings['dependencies']

  unless ::File.exists?("/opt/splunk/apps_installed/#{app_name}.#{settings['version']}")

    if settings['remote_download']
      remote_file "/opt/splunk/etc/apps/#{app_name}.#{settings['version']}.tar.gz" do
        source settings['file']
        checksum settings['checksum']
        action :create_if_missing
      end
    else
      cookbook_file "/opt/splunk/etc/apps/#{settings['file']}" do
        source "apps/#{settings['file']}"
        checksum settings['checksum']
        action :create_if_missing
      end
    end

    execute "Extracting #{settings['file']}" do
      command "cd /opt/splunk/etc/apps; tar -zxf #{app_name}.#{settings['version']}.tar.gz"
      notifies :restart, 'service[splunk]'
    end

    directory "/opt/splunk/etc/apps/#{app_name}/local" do
      owner 'root'
      group 'root'
    end

    file "/opt/splunk/apps_installed/#{app_name}.#{settings['version']}" do
      content settings['version']
    end

    new_resource.updated_by_last_action(true)
  end

  copy_templates app_name, settings['templates']
end

private

def install_dependencies(dep)
  unless dep.nil? || dep.empty?
    dep.each do |pkg|
      package pkg do
        action :install
      end
    end
  end
end

def copy_templates(app_name, templates)
  unless templates.nil? || templates.empty?
    templates.each do |templ|
      template "/opt/splunk/etc/apps/#{app_name}/local/#{templ.split('.erb').pop}" do
        source "apps/#{app_name}/#{templ}"
        owner 'root'
        group 'root'
        mode '0600'
        notifies :restart, 'service[splunk]'
      end
    end
  end
end
