#!/usr/bin/env ruby
require_relative '../lib/ur-sock'
#require 'ur-sock'

conf = UR::XMLConfigFile.new "test.conf.xml"
output_names, output_types = conf.get_recipe('out')
setp_names, setp_types = conf.get_recipe('setp')

con     = UR::Rtde.new('localhost').connect
version = con.controller_version

if not con.send_output_setup(output_names, output_types)
  puts 'Unable to configure output'
end

setp = con.send_input_setup(setp_names, setp_types)

setp["speed_slider_mask"] = 1
setp["speed_slider_fraction"] = 0

if not con.send_start
  puts 'Unable to start synchronization'
end

con.send(setp)

begin
  while true
    data = con.receive
    if data
      puts data["timestamp"].round.to_s + "\t" + data["actual_TCP_pose"].to_s
    end
  end
rescue Interrupt => e
  puts 'Interrrupt: ' + e.to_s
rescue SignalException => e
  puts 'signal exception'
  con.send_pause
  con.disconnect
rescue Exception => e
  puts 'Exception: ' + e.to_s
  con.send_pause
  con.disconnect
end
