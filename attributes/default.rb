include_attribute "kagent"
include_attribute "ndb"
include_attribute "hops"
include_attribute "kzookeeper"

default['hive2']['user']                    = node['install']['user'].empty? ? "hive" : node['install']['user']
default['hive2']['group']                   = node['install']['user'].empty? ? node['hops']['group'] : node['install']['user']
default['hive2']['version']                 = "2.3.0.1"
default['hive2']['url']                     = "#{node['download_url']}/apache-hive-#{node['hive2']['version']}-bin.tar.gz"
default['hive2']['port']                    = "9084"
default['hive2']['portssl']                 = "9085"
default['hive2']['dir']                     = node['install']['dir'].empty? ? "/srv" : node['install']['dir']
default['hive2']['home']                    = node['hive2']['dir'] + "/apache-hive-" + node['hive2']['version'] + "-bin"
default['hive2']['base_dir']                = node['hive2']['dir'] + "/apache-hive"
default['hive2']['logs_dir']                = node['hive2']['base_dir'] + "/logs"
default['hive2']['hopsfs_dir']              = "/apps/hive"
default['hive2']['scratch_dir']             = "/tmp/hive"
default['hive2']['keystore']                = "#{node['kagent']['base_dir']}/node_server_keystore.jks"
default['hive2']['keystore_password']       = "changeit"

default['hive2']['mysql_user']              = "hive"
default['hive2']['mysql_password']          = "hive"
default['hive2']['mysql_connector_version'] = "5.1.29"
default['hive2']['mysql_connector_url']     = "#{node['download_url']}/mysql-connector-java-#{node['hive2']['mysql_connector_version']}-bin.jar"
default['hive2']['mysql_connector_checksum'] = "32ddcf6d2613c79595f4f3fda01efb8620ea2bf50df954215c175ebec4cc67b9"

default['hive2']['metastore']['port']       = "9083"
default['hive2']['systemd']                 = "true"

default['hive2']['hive_cleaner']['version']   = "0.1.2"
default['hive2']['hive_cleaner']['url']       = "#{node['download_url']}/hivecleaner/#{node['platform_family']}/hivecleaner-#{node['hive2']['hive_cleaner']['version']}.tar.gz"
default['hive2']['hive_cleaner']['pid_file']  = "/tmp/hc.pid"

default['tez']['user']                    =  node['install']['user'].empty? ? "tez" : node['install']['user']
default['tez']['group']                   =  node['hops']['group']
default['tez']['version']                 = "0.8.5"
default['tez']['url']                     = "#{node['download_url']}/apache-tez-#{node['tez']['version']}.tar.gz"
default['tez']['dir']                     =  node['install']['dir'].empty? ? "/srv" : node['install']['dir']
default['tez']['home']                    =  node['tez']['dir'] + "/apache-tez-" + node['tez']['version']
default['tez']['base_dir']                =  node['tez']['dir'] + "/apache-tez"
default['tez']['hopsfs_dir']              = "/apps/tez"
default['tez']['conf_dir']                =  node['tez']['base_dir'] + "/conf"

default['slider']['user']                    =  node['install']['user'].empty? ? "slider" : node['install']['user']
default['slider']['group']                   =  node['hops']['group']
default['slider']['version']                 = "0.93.0-incubating-SNAPSHOT"
default['slider']['url']                     = "#{node['download_url']}/slider-#{node['slider']['version']}-all.tar.gz"
default['slider']['dir']                     =  node['install']['dir'].empty? ? "/srv" : node['install']['dir']
default['slider']['home']                    =  node['slider']['dir'] + "/apache-slider-" + node['slider']['version']
default['slider']['base_dir']                =  node['slider']['dir'] + "/apache-slider"

default['hive2']['execution_mode']         = "llap"
default['llap']['cluster_name']            = "hops-llap"
default['llap']['execution_mode']          = "auto"

default['tez']['session_per_queue']     = 100

default['hive2']['conf']['mapreduce_input_size']     = "134217728"