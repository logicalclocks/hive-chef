# Install Slider
group node['hops']['group'] do
  gid node['hops']['group_id']
  action :create
  not_if "getent group #{node['hops']['group']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

user node['slider']['user'] do
  home "/home/#{node['slider']['user']}"
  action :create
  shell "/bin/bash"
  manage_home true
  not_if "getent passwd #{node['slider']['user']}"
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

group node['hops']['group'] do
  action :modify
  members ["#{node['slider']['user']}"]
  append true
  not_if { node['install']['external_users'].casecmp("true") == 0 }
end

package_url = "#{node['slider']['url']}"
base_package_filename = File.basename(package_url)
cached_package_filename = "/tmp/#{base_package_filename}"

remote_file cached_package_filename do
  source package_url
  owner "#{node['slider']['user']}"
  mode "0644"
  action :create_if_missing
end

# Extract Slider
slider_downloaded = "#{node['slider']['home']}/.slider_extracted_#{node['slider']['version']}"

bash 'extract-slider' do
        user "root"
        group node['hops']['group']
        code <<-EOH
                set -e
                tar zxf #{cached_package_filename} -C /tmp
                mv /tmp/slider-#{node['slider']['version']} #{node['slider']['home']}
                # remove old symbolic link, if any
                rm -f #{node['slider']['base_dir']}
                ln -s #{node['slider']['home']} #{node['slider']['base_dir']}
                chown -R #{node['slider']['user']}:#{node['hops']['group']} #{node['slider']['home']}
                chown -R #{node['slider']['user']}:#{node['hops']['group']} #{node['slider']['base_dir']}
                touch #{slider_downloaded}
                chown -R #{node['slider']['user']}:#{node['hops']['group']} #{slider_downloaded}
        EOH
     not_if { ::File.exists?( "#{slider_downloaded}" ) }
end

# Export Slider HOME
magic_shell_environment 'SLIDER_HOME' do
  value "#{node['slider']['base_dir']}"
end

# Add Slider to PATH
magic_shell_environment 'PATH' do
  value "$PATH:#{node['slider']['base_dir']}/bin"
end


