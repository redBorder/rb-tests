#!/usr/bin/env ruby 

#
# Script to send MSE tests data
#

require 'optparse'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

USAGE = 'Usage: rb_send_mse_data.rb [options] ip_manager auth_token subscriptionName'
PATH = '/feed/v1/mse'

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
  request = Net::HTTP::Post.new("#{endpoint}?auth_token=#{auth_token}")
  request.add_field('Content-Type', 'application/json')
  request.body = payload.to_json
  puts "PAYLOAD: #{request.body}"
  http.request(request)
end

def generate_payload (subscriptionName)
  d = {
    notifications: [ {
      lastSeen: "2015-12-18T02:29:29.506-0800",
      service_provider: "E2E_3_MT3",
      notificationType: "locationupdate",
      timestamp: Time.now.to_i, #Timestamp with current time.
      subscriptionName: subscriptionName,
      entity: "WIRELESS_CLIENTS",
      band: nil,
      sensor_name: "MSE_on_CIS",
      locationMapHierarchy: "Cisco Sysetm 3rd>Building Q>First Floor",
      deviceId: "00:cc:bb:02:06:55",
      locationCoordinate: {
        unit: "FEET",
        x: 324.13867,
        y: 209.27563,
        z: 0
      },
      apMacAddress: "00:cc:bb:00:75:00",
      geoCoordinate: {
        lattitude: -999,
        longitude: -999,
        unit: "DEGREES"
      },
      confidenceFactor: 136,
      ssid: "snow-ball-tsim",
      floorId: -4564286733578928000,
      sensor_uuid: "4961405724351014752",
      service_provider_uuid: "SP-2353640801171667"
    } ]
  }
	d
end


def send_mse_data(manager_url, auth_token, subscriptionName)
	payload = generate_payload(subscriptionName)
	res = post(manager_url, PATH, auth_token, payload)
  puts "RESPONSE:\n#{res.body}"
  if res.body.empty?
    puts "MSE Data send suscessfully"
    @exitstatus=0
  else
    puts "Error when try to send MSE data"
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
subscriptionName = ARGV[2]

send_mse_data(manager_url, auth_token, subscriptionName)
exit @exitstatus


