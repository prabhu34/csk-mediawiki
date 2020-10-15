#
# Cookbook:: tw-mediawiki
# Recipe:: Setup
# Author:: Prabhu
# Description: Setup and configuration
# Copyright:: 2020, The Authors, All Rights Reserved.

[ "httpd", "php", "php-mysqlnd", "php-gd", "php-xml", "mariadb-server", "mariadb", "php-mbstring", "php-json", "php-fpm" ].each do |packagename|
  package "#{packagename}" do
    action :install
  end
end

[ "httpd", "mariadb", "firewalld", "php-fpm" ].each do |servicename|
  service "#{servicename}" do
     action [ :enable, :start ]
  end
end

bash "mysql_secure_installation" do
  code <<-EOH
    mysql -u root -e "CREATE USER '#{node['mediawiki']['dbUser']}'@'localhost' IDENTIFIED BY '#{node['mediawiki']['commonPass']}';"
    mysql -u root -e "CREATE DATABASE #{node['mediawiki']['dbName']};"
    mysql -u root -e "GRANT ALL PRIVILEGES ON #{node['mediawiki']['dbName']}.* TO '#{node['mediawiki']['dbUser']}'@'localhost';"
    mysql -u root -e "FLUSH PRIVILEGES;"
  EOH
end

[ "httpd", "mariadb", "firewalld", "php-fpm" ].each do |servicename|
  service "#{servicename}" do
     action [ :restart ]
  end
end

#remote_file "/tmp/mediawiki-1.34.4.tar.gz" do
#  source 'https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.4.tar.gz'
#  owner 'apache'
#  group 'apache'
#  mode '0755'
#  action :create
#end

tar_extract 'https://releases.wikimedia.org/mediawiki/1.34/mediawiki-1.34.4.tar.gz' do
  target_dir '/var/www'
  download_dir '/tmp'
  user 'root'
  group 'root'
end

directory "/var/www/mediawiki*" do
  mode '0644'
  owner 'apache'
  group 'apache'
  action :create
  recursive true
end

#archive_file '/tmp/mediawiki-1.34.4.tar.gz' do
#  path '/tmp/mediawiki-1.34.4.tar.gz'
#  destination '/var/www/'
#  action :extract
#end

link '/var/www/mediawiki' do
  to '/var/www/mediawiki-1.34.4'
  owner 'apache'
  group 'apache'
  mode '0755'
end

[ "http", "https" ].each do |zone|
  firewalld_service "#{zone}" do
    action :add
    zone 'public'
  end
end

execute 'selinux-conf' do
  command 'restorecon -FR /var/www/mediawiki*'
end

cookbook_file '/etc/httpd/conf/httpd.conf' do
  source 'httpd.conf'
  owner 'root'
  group 'root'
  mode '0600'
  action :create
end

cookbook_file '/var/www/mediawiki/resources/assets/logo.png' do
  source 'wiki.png'
  owner 'apache'
  group 'apache'
  mode '0644'
  action :create
end

#template '/var/www/mediawiki/LocalSettings.php' do
#  source 'LocalSettings.php.erb'
#  owner 'apache'
#  group 'apache'
#  mode '0600'
#end

bash "post_installation_configure" do
  code <<-EOH
    php /var/www/mediawiki/maintenance/install.php --lang=en --dbtype=mysql --dbname=#{node['mediawiki']['dbName']} --dbpass=#{node['mediawiki']['commonPass']} --dbserver=localhost --dbuser=#{node['mediawiki']['dbUser']} --server http://#{node['cloud']['public_ipv4']} --scriptpath="" --quiet --conf=#{node['mediawiki']['localSettingsConf']} --mwdebug=true --installdbuser=root --pass #{node['mediawiki']['commonPass']} --with-extensions "#{node['mediawiki']['wikiName']}" "#{node['mediawiki']['wikiUserName']}"
EOH
end

[ "httpd", "mariadb", "firewalld", "php-fpm" ].each do |servicename|
  service "#{servicename}" do
     action [ :restart ]
  end
end
