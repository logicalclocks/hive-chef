#include_recipe "hops::wrap"

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


endpoint = "http"
if node['install'].attribute?("ssl") == true
  if node['install']['ssl'] == "true"
    endpoint = "https"
  end
end

hopsworks_endpoint =

if node.attribute? "hopsworks"
  begin
    if node['hopsworks'].attribute? "port"
      hopsworks_endpoint = "#{endpoint}://" + private_recipe_ip("hopsworks", "default") + ":" + node['hopsworks']['port']
    else
      hopsworks_endpoint = "#{endpoint}://" + private_recipe_ip("hopsworks", "default") + ":" + node['hive2']['hopsworks']['port']
    end
  rescue
    dashboard_endpoint =
    Chef::Log.warn "could not find the hopsworks server ip to register kagent to!"
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


file "#{node['hive2']['base_dir']}/conf/hive-site.xml" do
  action :delete
end

template "#{node['hive2']['base_dir']}/conf/hive-site.xml" do
  source "hive-site.xml.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  mode 0655
  variables({
              :private_ip => my_ip,
              :hopsworks_endpoint => hopsworks_endpoint,
              :nn_endpoint => nn_endpoint,
              :mysql_endpoint => mysql_endpoint,
              :metastore_ip => metastore_ip,
              :zk_endpoints => zk_endpoints
            })
end

file "#{node['hive2']['base_dir']}/conf/hiveserver2-site.xml" do
  action :delete
end

template "#{node['hive2']['base_dir']}/conf/hiveserver2-site.xml" do
  source "hiveserver2-site.xml.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  mode 0655
end

file "#{node['hive2']['base_dir']}/conf/hive-env.sh" do
  action :delete
end

template "#{node['hive2']['base_dir']}/conf/hive-env.sh" do
  source "hive-env.sh.erb"
  owner node['hive2']['user']
  group node['hive2']['group']
  mode 0655
end
