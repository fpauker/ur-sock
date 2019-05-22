#!/usr/bin/env ruby
require_relative '../lib/ur-sock'
#require 'ur-sock'

conf = UR::XMLConfigFile.new "test.conf.xml"
output_names, output_types = conf.get_recipe('out')

con     = UR::Rtde.new('192.168.56.101').connect
version = con.controller_version

### Setup output
if not con.send_output_setup(output_names, output_types)
  puts 'Unable to configure output'
end
if not con.send_start
  puts 'Unable to start synchronization'
end

### Set Speed to very slow
# speed_names, speed_types = conf.get_recipe('speed')
# speed = con.send_input_setup(speed_names, speed_types)
# speed["speed_slider_mask"] = 1
# speed["speed_slider_fraction"] = 0
# con.send(speed)

begin
  while true
    data = con.receive
    if data
      puts con.robotmode[data['robot_mode']]
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
