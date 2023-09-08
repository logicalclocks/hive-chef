mysql_endpoint = "127.0.0.1:#{node['ndb']['mysql_port']}"

# Add user hive to hadoop secure group as it needs access to ssl-server.xml
# to read keymanagers reload interval
group node['hops']['secure_group'] do
  action :modify
  members node['hive2']['user']
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

# Logging
bash 'Move Hive logs to data volume' do
  user 'root'
  code <<-EOH
    set -e
    mv -f #{node['hive2']['logs_dir']}/* #{node['hive2']['data_volume']['logs_dir']}
    rm -rf #{node['hive2']['logs_dir']}
  EOH
  only_if { conda_helpers.is_upgrade }
  only_if { File.directory?(node['hive2']['logs_dir'])}
  not_if { File.symlink?(node['hive2']['logs_dir'])}
end

link node['hive2']['logs_dir'] do
  owner node['hive2']['user']
  group node['hops']['group']
  mode '0775'
  to node['hive2']['data_volume']['logs_dir']
end

template "#{node['hive2']['conf_dir']}/hive-log4j2.properties" do
  source "hive-log4j2.properties.erb"
  owner node['hive2']['user']
  group node['hops']['group']
  mode "0655"
end

hopsworks_port = "8182"
if node['hopsworks'].attribute?('internal') and node['hopsworks']['internal'].attribute?('port')
  hopsworks_port = node['hopsworks']['internal']['port']
end

hopsworks_fqdn = consul_helper.get_service_fqdn("http.glassfish")
hopsworks_endpoint = "https://#{hopsworks_fqdn}:#{hopsworks_port}"

nn_fqdn = consul_helper.get_service_fqdn("namenode")
namenode_endpoint = "#{nn_fqdn}:#{node['hops']['nn']['port']}"

metastore_fqdn = consul_helper.get_service_fqdn("metastore.hive")

magic_shell_environment 'HADOOP_HOME' do
  value "#{node['hops']['base_dir']}"
end

magic_shell_environment 'HIVE_HOME' do
  value "#{node['hive2']['base_dir']}"
end

magic_shell_environment 'PATH' do
  value "$PATH:#{node['hops']['base_dir']}/bin:#{node['hive2']['base_dir']}/bin"
end

#
# See Cloudera tutorial for installing metastore with MySQL
# https://www.cloudera.com/documentation/enterprise/5-8-x/topics/cdh_ig_hive_metastore_configure.html
#
# and this one:
# http://www.toadworld.com/platforms/oracle/w/wiki/11427.using-mysql-database-as-apache-hive-metastore-database
#

template "#{node['hive2']['conf_dir']}/hive-site.xml" do
  source "hive-site.xml.erb"
  owner node['hive2']['user']
  group node['hops']['secure_group']
  mode 0650
  variables( lazy {
    {
      :hopsworks_endpoint => hopsworks_endpoint,
      :nn_endpoint => namenode_endpoint,
      :mysql_endpoint => mysql_endpoint,
      :metastore_fqdn => metastore_fqdn
    }
  })
  action :create
end

template "#{node['hive2']['conf_dir']}/hiveserver2-site.xml" do
  source "hiveserver2-site.xml.erb"
  owner node['hive2']['user']
  group node['hops']['secure_group']
  mode 0650
  action :create
end

template "#{node['hive2']['conf_dir']}/hive-env.sh" do
  source "hive-env.sh.erb"
  owner node['hive2']['user']
  group node['hops']['group']
  mode 0655
  action :create
end