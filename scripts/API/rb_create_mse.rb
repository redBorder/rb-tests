#!/usr/bin/env ruby 
#
# This script allow users create an MSE sensor
#
require 'optparse'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

USAGE = 'Usage: rb_create_mse.rb [options] ip_manager auth_token sensor_name stream'
BASE_API = '/api/v1'


# Load options from the command line
def load_options
  options_tmp = {}
  options = nil
  OptionParser.new do |opts|
    opts.banner = USAGE    
    opts.on('-h', '--help', 'Show this help') { |v| options_tmp[:help] = true }
    options = opts
  end.parse!
  if ARGV.size < 3 || options_tmp[:help]
    puts options
    exit
  end  
  options_tmp
end

# Perform a PUT HTTP request with a given payload
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
  puts "PAYLOAD: #{request.body}"
  http.request(request)
end

def generate_payload (sensor_name, stream)
	d = {
		name: sensor_name,
    stream: stream
	}
	d
end


def create_mse(manager_url, auth_token, sensor_name, stream)
	endpoint = "/sensors/mse"
	payload = generate_payload(sensor_name, stream)
	res = post(manager_url, endpoint, auth_token, payload)
	json = JSON.parse(res.body)
	puts "RESPONSE: #{res.body}"
	if json['query']
		puts "MSE Sensor #{sensor_name} created susccesfully"
    puts "UUID: #{json['sensor']['uuid']}"
    @exitstatus=0
	else
    puts "Error when try to create MSE sensor #{sensor_name}"
    @exitstatus=1
	end
end

#
# MAIN EXECUTION
#

# Parse options
options = load_options
manager_url = ARGV[0]
auth_token = ARGV[1]
sensor_name = ARGV[2]
stream = ARGV[3]

create_mse(manager_url, auth_token, sensor_name, stream)
exit @exitstatus


