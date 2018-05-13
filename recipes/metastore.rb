include_recipe "hive2::_configure"

private_ip = my_private_ip()
public_ip = my_public_ip()

bash 'setup-hive' do
  user "root"
  group node['hive2']['group']
  code <<-EOH
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"CREATE DATABASE IF NOT EXISTS metastore CHARACTER SET latin1\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT ALL PRIVILEGES ON metastore.* TO '#{node['hive2']['mysql_user']}'@'#{private_ip}' IDENTIFIED BY '#{node['hive2']['mysql_password']}'\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT ALL PRIVILEGES ON metastore.* TO '#{node['hive2']['mysql_user']}'@'#{public_ip}' IDENTIFIED BY '#{node['hive2']['mysql_password']}'\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT ALL PRIVILEGES ON metastore.* TO '#{node['hive2']['mysql_user']}'@'#{node['hostname']}' IDENTIFIED BY '#{node['hive2']['mysql_password']}'\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT SELECT ON hops.hdfs_inodes TO '#{node['hive2']['mysql_user']}'@'#{private_ip}' IDENTIFIED BY '#{node['hive2']['mysql_password']}'\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT SELECT ON hops.hdfs_inodes TO '#{node['hive2']['mysql_user']}'@'#{public_ip}' IDENTIFIED BY '#{node['hive2']['mysql_password']}'\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"GRANT SELECT ON hops.hdfs_inodes TO '#{node['hive2']['mysql_user']}'@'#{node['hostname']}' IDENTIFIED BY '#{node['hive2']['mysql_password']}'\"
        #{node['ndb']['scripts_dir']}/mysql-client.sh -e \"FLUSH PRIVILEGES\"
        EOH
  not_if "#{node['ndb']['scripts_dir']}/mysql-client.sh -e \"SHOW DATABASES\" | grep metastore"
end

bash 'schematool' do
  user node['hive2']['user']
  group node['hive2']['group']
  code <<-EOH
        #{node['hive2']['base_dir']}/bin/schematool -dbType mysql -initSchema
        EOH
  not_if "#{node['ndb']['scripts_dir']}/mysql-client.sh -e \"use metastore; SHOW TABLES;\" | grep -i SDS"
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
