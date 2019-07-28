include_recipe "hive2::_configure"

# Template HiveServer2 for the JMX prometheus exporter
cookbook_file "#{node['hive2']['conf_dir']}/hiveserver2.yaml" do
  source 'hiveserver2.yaml'
  owner node['hive2']['user']  
  group node['hive2']['group'] 
  mode '0755'
  action :create
end

deps = ""
if exists_local("ndb", "mysqld") 
  deps = "mysqld.service "
end  
if exists_local("hive2", "metastore") || exists_local("hive2", "default")
  deps += "hivemetastore.service"
end
service_name="hiveserver2"

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
  variables({
            :deps => deps
           })
  if node['services']['enabled'] == "true"
    notifies :enable, resources(:service => service_name)
  end
end

kagent_config service_name do
  action :systemd_reload
end

if node['kagent']['enabled'] == "true"
  kagent_config service_name do
    service "Hive"
    log_file node['hive2']['logs_dir'] + "/hive.log"
  end
end

if node['install']['upgrade'] == "true"
  kagent_config "#{service_name}" do
    action :systemd_reload
  end
end  
