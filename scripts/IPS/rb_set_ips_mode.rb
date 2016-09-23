#!/usr/bin/ruby

require 'rubygems'
require 'getopt/std'

def usage
  printf "Usage: rb_set_ips_mode.rb [OPTIONS] \n"
  printf "   -s sensor Nodename\n"
  printf "   -m mode (IDS_SPAN, IDS_FWD, IPS, IPS_TEST)\n"
  printf "   -g group\n"
  printf "   -v verbose\n"
  printf ""
  printf "Example: rb_set_ips_mode.rb -s rbips-8 -m IDS_SPAN -g 0\n"
end

#Getting options
opt = Getopt::Std.getopts("hs:m:v:g")

if !opt["h"]

  require 'chef'
  require 'json'

  # Checking arguments
  if !opt["s"] or !opt["m"] or !opt["g"]
    puts "\n[ERROR] Some params are missing\n\n" 
    usage
    exit 1
  else
    sensor = opt["s"]    
    group = opt["g"]

    mode = opt["m"]
    unless mode == "IDS_SPAN" or mode == "IDS_FWD" or mode == "IPS" or mode == "IPS_TEST"
      puts "\n[ERROR] Invalid sensor mode selected\n\n"
      usage
      exit 1
    end
  end

  #Configuring Chef parameters
  Chef::Config.from_file("/etc/chef/client.rb")
  Chef::Config[:node_name]  = "rb-chef-webui"
  Chef::Config[:client_key] = "/opt/rb/var/www/rb-rails/config/rb-chef-webui.pem"
  Chef::Config[:http_retry_count] = 5

  # get sensor
  role_name = `knife node show #{sensor} | grep "role" | awk {'print $4'} | cut -d "[" -f 2 | cut -d "]" -f 1`.delete! "\n"

  #Generating json tree
  role = Chef::Role.load("#{role_name}")
  role.override_attributes["redBorder"] = {} if role.override_attributes["redBorder"].nil?
  role.override_attributes["redBorder"]["snort"] = {} if role.override_attributes["redBorder"]["snort"].nil?
  role.override_attributes["redBorder"]["snort"]["groups"] = {} if role.override_attributes["redBorder"]["snort"]["groups"].nil?
  role.override_attributes["redBorder"]["snort"]["groups"]["0"] = {} if role.override_attributes["redBorder"]["snort"]["groups"]["0"].nil?
  role.override_attributes["redBorder"]["snort"]["groups"]["0"]["mode"] = {} if role.override_attributes["redBorder"]["snort"]["groups"]["0"]["mode"].nil?

  # Set sensor mode
  mode = opt["m"]
  role.override_attributes["redBorder"]["snort"]["groups"]["0"]["mode"].replace(mode) 
  
  #Saving role changes
  if role.save
    printf "role[manager] saved successfully\n"
    exit 0
  else
    printf "ERROR: role[manager] cannot be saved!!!\n"
    exit 1
  end
else
  usage
  exit 1
end
