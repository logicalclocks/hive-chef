my_ip = my_private_ip()
nn_endpoint = private_recipe_ip("hops", "nn") + ":#{node['hops']['nn']['port']}"

zk_ips = private_recipe_ips('kzookeeper', 'default')
zk_endpoints = zk_ips.join(",")

mysql_endpoint = private_recipe_ip("ndb", "mysqld") + ":#{node['ndb']['mysql_port']}"

# Logging
directory "#{node['hive2']['logs_dir']}" do
  owner node['hive2']['user']
  group node['hive2']['group']
  mode "0775"
  action :create
end

template "#{node['hive2']['base_dir']}/conf/hive-log4j2.properties" do
  source "hive-log4j2.properties.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  mode "0655"
end

hopsworks_endpoint =
if node.attribute? "hopsworks"
  begin
    if node['hopsworks'].attribute? "https" and node['hopsworks']['https'].attribute? "port"
      hopsworks_endpoint = "https://" + private_recipe_ip("hopsworks", "default") + ":" + node['hopsworks']['https']['port']
    else
      hopsworks_endpoint = "https://" + private_recipe_ip("hopsworks", "default") + ":8181"
    end
  rescue
    dashboard_endpoint = ""
  end
end


begin
  metastore_ip = private_recipe_ip("hive2", "metastore")
rescue
  metastore_ip = private_recipe_ip("hive2", "default")
  Chef::Log.warn "Using default ip for metastore (metastore service not defined in cluster definition (yml) file."
end

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

template "#{node['hive2']['base_dir']}/conf/hive-site.xml" do
  source "hive-site.xml.erb"
  owner node['hive2']['user']
  group node['hops']['secure_group']
  mode 0650
  variables({
    :private_ip => my_ip,
    :hopsworks_endpoint => hopsworks_endpoint,
    :nn_endpoint => nn_endpoint,
    :mysql_endpoint => mysql_endpoint,
    :metastore_ip => metastore_ip,
    :zk_endpoints => zk_endpoints
  })
  action :create
end

template "#{node['hive2']['base_dir']}/conf/hiveserver2-site.xml" do
  source "hiveserver2-site.xml.erb"
  owner node['hive2']['user']
  group node['hops']['secure_group']
  mode 0650
  action :create
end

template "#{node['hive2']['base_dir']}/conf/hive-env.sh" do
  source "hive-env.sh.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  mode 0655
  action :create
end
