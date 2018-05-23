include_recipe "java"

# Create the hiveCleaner directory if it doesn't exist
directory node['hive2']['cleaner']['parent'] do
  owner node['hive2']['user']
  group node['hive2']['group']
  action :create
end

# Download Hive cleaner
package_url = "#{node['hive2']['cleaner']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "/tmp/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner node['hive2']['user']
  group node['hive2']['group']
  mode "0644"
  action :create_if_missing
end

cleaner_downloaded = "#{node['hive2']['cleaner']['parent']}/.cleaner_extracted_#{node['hive2']['cleaner']['version']}"
bash 'extract-cleaner' do
  user "root"
  group node['hive2']['group']
  code <<-EOH
    set -e
    tar zxf #{cached_package_filename} -C /tmp
    mv /tmp/hivecleaner-#{node['hive2']['cleaner']['version']} #{node['hive2']['cleaner']['parent']}
    chown -R #{node['hive2']['user']}:#{node['hive2']['group']} #{node['hive2']['cleaner']['home']}
    touch #{cleaner_downloaded}
  EOH
  not_if { ::File.exists?( "#{cleaner_downloaded}" ) }
end

# Create the log directory
directory "#{node['hive2']['cleaner']['home']}/logs" do
  user node['hive2']['user']
  group node['hive2']['group']
  action :create
end

link node['hive2']['cleaner']['base_dir'] do
  to node['hive2']['cleaner']['home']
end

#Add the wiper
template "#{node['hive2']['cleaner']['parent']}/wiper.sh" do
  source "wiper.sh.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  action :create
  mode 0755
end

ndb_mgmd_ip = private_recipe_ip("ndb", "mgmd")
template "#{node['hive2']['cleaner']['parent']}/start-hivecleaner.sh" do
  source "start-hivecleaner.sh.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  variables({
      :mgmd_endpoint => ndb_mgmd_ip
  })
  mode 0775
end

service_name="hivecleaner"
case node['platform_family']
when "rhel"
  systemd_script = "/usr/lib/systemd/system/#{service_name}.service"
else
  systemd_script = "/lib/systemd/system/#{service_name}.service"
end

service service_name do
  provider Chef::Provider::Service::Systemd
  supports :restart => true, :stop => true, :start => true, :status => true
  action :nothing
end

template systemd_script do
  source "#{service_name}.service.erb"
  owner "root"
  group "root"
  mode 0754
  if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => service_name)
  end
end

kagent_config service_name do
  action :systemd_reload
end

# TODO(fabio) restart hiveCleaner after upgrade.
if node['kagent']['enabled'] == "true"
   kagent_config service_name do
     service "Hive"
     log_file node['hive2']['cleaner']['base_dir'] + "/logs/hivecleaner.log"
   end
end

