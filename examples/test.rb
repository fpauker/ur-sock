#!/usr/bin/env ruby
require 'logger'
require_relative 'rtde'
require_relative 'rtde_conf'

conf = ConfigFile.new "record_configuration.xml"
output_names, output_types = conf.get_recipe('out')


con = Rtde.new('localhost').connect

version = con.get_controller_version

if not con.send_output_setup(output_names, output_types, 125)
  puts('Unable to configure output')
end

if not con.send_start
  puts('Unable to start synchronization')
end

begin
  # Loop indefinitely
  while true
    data = con.receive
    if data
      puts data["timestamp"].round.to_s + "\t" + data["actual_TCP_pose"].to_s
    end
  end
rescue Interrupt => e
  puts "Interrrupt:" +e.to_s
rescue SignalException => e
  puts  'signal exception'
  con.send_pause
  con.disconnect
rescue Exception => e
  puts "Exception:" + e.to_s
  con.send_pause
  con.disconnect
end
