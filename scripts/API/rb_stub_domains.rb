#!/usr/bin/env ruby 
#
# This script allow the user to create an stub structure of sensors.
#
require 'optparse'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

# -------------------------------------------------------
# Constants
# -------------------------------------------------------

# Usage of the script
USAGE = 'Usage: ./stub_domains.rb [options] ip_manager auth_token sensor_uuid'
# Base api url
BASE_API = '/api/v1'
# Defaults
NUM_CHILDREN = 3
DEPTH = 3
OVERRIDE = false
APS = 0
RATE = 0
THREAD_LIMIT = 200
UUID_TO_DELETE = 0

# Created domains
@created_domains = 0
# Correct Requests
@correct_requests = 0
# Wrong POSTS
@post_errors = 0
# Wrong DELETES
@delete_errors = 0

# -------------------------------------------------------
# Functions
# -------------------------------------------------------

# Load options from the command line
def load_options
  options_tmp = {}
  options = nil

  OptionParser.new do |opts|
    opts.banner = USAGE
    opts.on('-c', '--children-number INTEGER', 'Number of children on every domain (Default: 3)') { |v| options_tmp[:num_children] = v.to_i }
    opts.on('-d', '--depth INTEGER', 'Depth of children (Default: 3)') { |v| options_tmp[:depth] = v.to_i }
    opts.on('-o', '--override', 'Override the parent structure (Default: false)') { |v| options_tmp[:override] = true }
    opts.on('-a', '--add-aps INTEGER', 'Add some stubs aps (Default: 0)') { |v| options_tmp[:aps] = v.to_i }
    opts.on('-r', '--rate INTEGER', 'Requests per second for performance testing') { |v| options_tmp[:rate] = v.to_i }
    opts.on('-p', '--thread-limit INTEGER', 'Limit of threads to use') { |v| options_tmp[:thread_limit] = v.to_i }
    opts.on('-d', '--delete STRING', 'Delete a domain with uuid provided') { |v| options_tmp[:uuid_to_delete] = v }
    opts.on('-h', '--help', 'Show this help') { |v| options_tmp[:help] = true }
    
    options = opts
  end.parse!

  if ARGV.size < 3 || options_tmp[:help]
    puts options
    exit
  end
  # Set defaults
  options_tmp[:num_children]   ||= NUM_CHILDREN
  options_tmp[:depth]          ||= DEPTH
  options_tmp[:override]       ||= OVERRIDE
  options_tmp[:aps]            ||= APS
  options_tmp[:rate]           ||= RATE
  options_tmp[:thread_limit]   ||= THREAD_LIMIT
  options_tmp[:uuid_to_delete] ||= UUID_TO_DELETE
  # Return!
  options_tmp
end

# Perform a POST HTTP request with a given payload
#
# == Parameters:
# endpoint::
#   String with the endpoint of the API. This will be concatenated with the
#   manager url
#
# == Returns:
# HTTP response
#
def post(url, endpoint, auth_token, payload)
  uri = URI.parse("#{url}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = 60 * 5
  if url.include?('https://')
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Post.new("#{BASE_API}#{endpoint}?auth_token=#{auth_token}")
  request.add_field('Content-Type', 'application/json')
  request.body = payload.to_json
  http.request(request)
end

# Perform a DELETE HTTP request
#
# == Parameters:
# endpoint::
#   String with the endpoint of the API. This will be concatenated with the
#   manager url
#
# == Returns:
# HTTP response
#
def delete(url, endpoint, auth_token)
  uri = URI.parse("#{url}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = 60 * 5
  if url.include?('https://')
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Delete.new("#{BASE_API}#{endpoint}?auth_token=#{auth_token}")
  http.request(request)
end

#
# Create a domain with a random name and returns the uuid of the element
# Returns 
#
def create_domain(uuid, depth, num_children, aps, url, endpoint, auth_token)
  uuid_created = ""
  num_children.times do
    domain = stub_domain(aps, uuid)
    # Set and return
    res = post(url, endpoint, auth_token, domain)
    json = JSON.parse(res.body)
    if !json.nil?
      if json['query']
        if !json['sensor'].nil?       
          uuid_created = json['sensor']['uuid']
          @created_domains += 1
          if depth > 1
          create_domain(json['sensor']['uuid'], depth - 1, num_children, aps,
                        url, endpoint, auth_token)
          end
        else          
          @post_errors +=1
          puts "ERROR! UUID DON'T FOUND"
          p json
        end
      else
        @post_errors += 1
        puts "ERROR! => #{json['error']}"              
      end
    else
      @post_errors += 1
      puts "ERROR!!! EMPTY RESPONSE"
      p json
    end
  end
  return uuid_created
end

#
# Create the HASH structure for override a domain
#
def override_structure(depth, num_children, aps)
  str = {
    sensor: { children: [] }
  }
  # Create childrens and return
  str[:sensor][:children] = create_children(depth, num_children, aps)
  str
end

#
# Create children for a node. Iterates over depth and number of childrens
#
def create_children(depth, num_children, aps)
  children = []

  num_children.times do
    domain = stub_domain aps
    domain[:children] = create_children(depth - 1, num_children, aps) if depth > 1
    # Add to children
    @created_domains += 1
    children << domain
  end

  children
end

#
# Return a custom hash for a domain
#
def stub_domain(aps, uuid = nil)
  d = {
    name: random_name,
    type: 1,
    domain_type: 3
  }
  d[:parent_uuid] = uuid if uuid
  d[:access_points] = stub_access_points(aps) if aps
  # Return stub domain
  d
end

#
# Return N access points for a sensor.
#
def stub_access_points(num)
  aps = []
  num.times do
    aps << {
      name: random_name,
      mac_address: random_mac
    }
  end
  # Return aps
  aps
end

#
# Random name
#
def random_name
  (0...20).map { ('a'..'z').to_a[rand(26)] }.join
end

#
# Random MAC address
#
def random_mac
  (1..6).map { "%0.2X"%rand(256) }.join(':')
end

#
# Signal handling
#
def terminate_script   
  $exit = true
  p "Waiting threads..."  
  threads = $thread_group.list
  threads.each do |thread|
    thread.join
  end  
  p "Threads finished"  
end

#
# Handler function that makes full requests.
#
def handler(options, manager_url, auth_token, uuid)
  uuid_created=""
  if options[:override]
    # Use override all method
    endpoint = "/sensors/#{uuid}/override_all"
    # Create the structure for override all
    data = override_structure(options[:depth], options[:num_children],
                              options[:aps])
    puts data
    # Set the data
    post(manager_url, endpoint, auth_token, data)
    # Finish
    puts "Finish! Override sensor with #{@created_domains} domains :D"
  else
    # Create new domains
    endpoint = '/sensors/domain'
    # Iterate
    uuid_created = create_domain(uuid, options[:depth], options[:num_children], options[:aps], manager_url, endpoint, auth_token)      
    if options[:rate] != 0
      delete_response = delete(manager_url, "/sensors/#{uuid_created}", auth_token)
      json = JSON.parse(delete_response.body)
      if !json['query']
        p "ERROR: not deleted"
        @delete_errors += 1
      end
    end
  end
  uuid_created
end

# -------------------------------------------------------
# Code
# -------------------------------------------------------

# Parse options
options = load_options
manager_url = ARGV[0]
auth_token = ARGV[1]
uuid = ARGV[2]

if options[:rate] == 0 and options[:uuid_to_delete] == 0 
  uuid_created = handler(options, manager_url, auth_token, uuid)
  puts "uuid_created: #{uuid_created}"
elsif options[:uuid_to_delete] != 0
  delete_response = delete(manager_url, "/sensors/#{options[:uuid_to_delete]}", auth_token)
  json = JSON.parse(delete_response.body)
  if !json['query']
    p "ERROR: not deleted"
    @delete_errors += 1
  end
else
  Signal.trap("TERM") { terminate_script }
  Signal.trap("INT") { terminate_script }
  $exit = false
  $thread_group = ThreadGroup.new
  while !$exit do
    if $thread_group.list.count < options[:thread_limit] 
      $thread_group.add Thread.new {
        p "New thread. Currently there are #{$thread_group.list.count} threads"
        handler(options, manager_url, auth_token, uuid)
        p "Finish this thread"
      }
    else
      p "Thread limit reached (#{options[:thread_limit]})"
      wait_index = 1
      while $thread_group.list.count < options[:thread_limit]
        sleep wait_index/options[:rate]
        wait_index += 1
      end      
    end
    sleep 1/options[:rate].to_f
  end
end
puts "Finish! Created #{@created_domains} domains :D"
puts "Post errors: #{@post_errors}"
puts "Delete errors: #{@delete_errors}"

if @post_errors > 0 or @delete_errors > 0
  exit 1
end
