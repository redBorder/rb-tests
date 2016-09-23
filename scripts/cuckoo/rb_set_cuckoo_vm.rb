#!/usr/bin/ruby

require 'rubygems'
require 'getopt/std'


def usage
  printf "Usage: rb_set_cuckoo_vm.rb [OPTIONS] \n"
  printf "   -l label (KVM machine label) Default: Win7-64\n"
  printf "   -p platform (OS platform) Default: windows\n"
  printf "   -s s3_path (S3 path of Cuckoo VM) Default: isos/Win7Mex64.qcow2\n"
  printf "   -n name (Cuckoo vm machine name) Default: cuckoo1\n"
  printf "   -i ip (ip of cuckoo vm machine) Default: 192.168.122.101. Range must be 192.168.122.101-254\n"
end

#Default parameters
label = "Win7-64"
platform = "windows"
s3_path = "isos/Win7Mex64.qcow2"
name = "cuckoo1"
ip = "192.168.122.101"

#Getting options
opt = Getopt::Std.getopts("hl:p:s:n:i:v")

if !opt["h"]
  
  require 'chef'
  require 'json'

  #Setting options
  label = opt["l"] if !opt["l"].nil? 
  platform = opt["p"] if !opt["p"].nil?
  s3_path = opt["s"] if !opt["s"].nil?
  name = opt["n"] if !opt["n"].nil?
  ip = opt["i"] if !opt["i"].nil?

  #Configuring Chef parameters
  Chef::Config.from_file("/etc/chef/client.rb")
  Chef::Config[:node_name]  = "rb-chef-webui"
  Chef::Config[:client_key] = "/opt/rb/var/www/rb-rails/config/rb-chef-webui.pem"
  Chef::Config[:http_retry_count] = 5
  
  #Generating json tree
  role = Chef::Role.load("manager")
  role.override_attributes["redBorder"] = {} if role.override_attributes["redBorder"].nil?
  role.override_attributes["redBorder"]["cuckoo"] = {} if role.override_attributes["redBorder"]["cuckoo"].nil?
  role.override_attributes["redBorder"]["cuckoo"]["machines"] = [] if role.override_attributes["redBorder"]["cuckoo"]["machines"].nil?
  p "machines = #{role.override_attributes["redBorder"]["cuckoo"]["machines"]}"
  p "cuckoo = #{role.override_attributes["redBorder"]["cuckoo"]}"
  if !opt["v"] 

    index = nil
    machine_found = false
    if !role.override_attributes["redBorder"]["cuckoo"]["machines"].nil? 
      role.override_attributes["redBorder"]["cuckoo"]["machines"].each do |machine|      
        if machine.key(name) == "name" and machine_found == false
          index = role.override_attributes["redBorder"]["cuckoo"]["machines"].index(machine)
          machine_found = true
          
          label = machine["label"] if opt["l"].nil? 
          platform = machine["platform"] if opt["p"].nil?
          s3_path = machine["s3_path"] if opt["s"].nil?
          name = machine["name"] if opt["n"].nil?
          ip = machine["ip"] if opt["i"].nil?
        end 
      end
    end
    if index.nil?       
      index = role.override_attributes["redBorder"]["cuckoo"]["machines"].length
     
    end

    #Printing chosen options
    printf "Parameters value: \n"
    printf "label    = #{label}\n"
    printf "platform = #{platform}\n"
    printf "s3_path  = #{s3_path}\n"
    printf "name     = #{name}\n"
    printf "ip       = #{ip}\n"

    #Writing parameters
    aux_hash = {
      "label" => label,
      "platform" => platform,
      "s3_path" => s3_path,
      "name" => name,
      "ip" => ip
    }
    if index == role.override_attributes["redBorder"]["cuckoo"]["machines"].length
      role.override_attributes["redBorder"]["cuckoo"]["machines"].push(aux_hash)
    else
      role.override_attributes["redBorder"]["cuckoo"]["machines"].at(index).replace(aux_hash)
    end

    #Saving role changes
    if role.save
      printf "role[manager] saved successfully\n"
    else
      printf "ERROR: role[manager] cannot be saved!!!\n"
    end

  else # -v option (view machines)
    role.override_attributes["redBorder"]["cuckoo"]["machines"].each do |machine|
      puts ("#{machine}")
    end
  end

else
  usage
end