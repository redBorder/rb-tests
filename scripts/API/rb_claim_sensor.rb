#!/usr/bin/env ruby 
#
# This script allow users to claim a sensor via API.
#
require 'optparse'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

USAGE = 'Usage: rb_claim_sensor.rb [options] ip_manager auth_token sensor_name sensor_uuid'
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
def put(url, endpoint, auth_token, payload)
  uri = URI.parse("#{url}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.read_timeout = 60 * 5
  if url.include?('https://')
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Put.new("#{BASE_API}#{endpoint}?auth_token=#{auth_token}")
  request.add_field('Content-Type', 'application/json')
  request.body = payload.to_json
  puts "PAYLOAD: #{request.body}"
  http.request(request)
end

def generate_payload (sensor_name, uuid)
	d = {
		name: sensor_name,
		uuid: uuid
	}
	d
end


def claim_sensor(manager_url, uuid, sensor_name, auth_token)
	endpoint = "/sensors/claim"
	payload = generate_payload(sensor_name, uuid)
	res = put(manager_url, endpoint, auth_token, payload)
	json = JSON.parse(res.body)
	puts "RESPONSE: #{res.body}"
	if json['status'] == "claimed"
		puts "Sensor with uuid #{uuid} claimed suscesfully"
	else
    puts "Error when try to claim sensor with uuid #{uuid}"
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
uuid = ARGV[3]

claim_sensor(manager_url, uuid, sensor_name, auth_token)




