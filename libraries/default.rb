# splunk helpers
#

module SplunkHelpers
  def cloud_support
    node.attribute?('cloud')
  end

  def configs_to_deploy(distributed, scripted_auth, dedicated_indexer, configs = [])
    configs << 'distsearch' if distributed
    configs << 'authentication' if scripted_auth
    configs << 'outputs' if !dedicated_indexer && distributed
    configs
  end

  def ec2_support
    node.attribute?('ec2')
  end

  def package_name(version, build, install_type)
    splunk_package_version = 'splunk' + (install_type == 'server' ? '' : 'forwarder') + "-#{version}-#{build}"

    splunk_file = splunk_package_version +
      case node['platform']
      when 'centos', 'redhat', 'fedora', 'amazon', 'scientific'
        if node['kernel']['machine'] == 'x86_64'
          '-linux-2.6-x86_64.rpm'
        else
          '.i386.rpm'
        end
      when 'debian', 'ubuntu'
        if node['kernel']['machine'] == 'x86_64'
          '-linux-2.6-amd64.deb'
        else
          '-linux-2.6-intel.deb'
        end
    end
    splunk_file
  end

  def package_url(root, version, file, install_type)
    "#{root}/#{version}/" + (install_type == 'server' ? 'splunk' : 'universalforwarder') + "/linux/#{file}"
  end

  def splunk_home(type, beta)
    if type == 'server'
      return '/opt/splunk'
    else
      return '/opt/splunkforwarder'
    end
  end
end
