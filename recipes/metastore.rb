include_recipe "hive2::_configure"

private_ip = my_private_ip()
public_ip = my_public_ip()

# Create hive apps and warehouse dirs
tmp_dirs = [node['hive2']['hopsfs_dir'] , node['hive2']['hopsfs_dir'] + "/warehouse"]
for d in tmp_dirs
  hops_hdfs_directory d do
    action :create_as_superuser
    owner node['hive2']['user']
    group node['hive2']['group']
    mode "1755" #warehouse must be readable&executable for SparkSQL to read from Hive
    not_if ". #{node['hops']['home']}/sbin/set-env.sh && #{node['hops']['home']}/bin/hdfs dfs -test -d #{d}"
  end
end

# Create hive user-dir on hdfs
hops_hdfs_directory "/user/#{node['hive2']['user']}" do
  action :create_as_superuser
  owner node['hive2']['user']
  group node['hive2']['group']
  mode "1751"
  not_if ". #{node['hops']['home']}/sbin/set-env.sh && #{node['hops']['home']}/bin/hdfs dfs -test -d #{"/user/#{node['hive2']['user']}"}"
end

# Create hive scratchdir on hdfs
hops_hdfs_directory node['hive2']['scratch_dir'] do
    action :create_as_superuser
    owner node['hive2']['user']
    group node['hive2']['group']
    mode "1777" #scratchdir must be read/write/executable by everyone for SparkSQL user-jobs to write there
    not_if ". #{node['hops']['home']}/sbin/set-env.sh && #{node['hops']['home']}/bin/hdfs dfs -test -d #{node['hive2']['scratch_dir']}"
end




service_name="hivemetastore"

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
