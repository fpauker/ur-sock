#!/usr/bin/env ruby
require_relative '../lib/ur-sock'

conf = UR::XMLConfigFile.new "bitreg.conf.xml"
output_names, output_types = conf.get_recipe('out')

con     = UR::Rtde.new('192.168.1.25').connect
version = con.controller_version

p con.connected?

### Set SBitregister
bitreg_names, bitreg_types = conf.get_recipe('bitreg')
reg = con.send_input_setup(bitreg_names, bitreg_types)



### Setup output
if not con.send_output_setup(output_names, output_types)
  puts 'Unable to configure output'
end
if not con.send_start
  puts 'Unable to start synchronization'
end

reg["input_bit_register_64"] = true
reg["input_int_register_0"] = 4
con.send(reg)


begin
  while true
    data = con.receive
    if data
      #puts UR::Rtde::ROBOTMODE[data['robot_mode']]
      puts data['input_bit_register_64']
      puts data['input_int_register_0']
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
  puts e.message
  con.send_pause
  con.disconnect
end
