#!/usr/bin/env ruby
require_relative '../lib/ur-sock'
#require 'ur-sock'
require_relative 'dashboard'

con     = UR::Dash.new('localhost').connect
con.power_on
con.break_release

con.popupmessage 'juegen & Flo'
sleep 5
con.load_program('test')
#con.set_operation_mode_auto
puts "Robotmode: " + con.get_robotmode.to_s

con.start_program
sleep 5

puts "Path:" + con.get_loaded_program.to_s



con.pause_program
sleep 5
con.start_program
con.get_robotmode
sleep 5
con.stop_program
#con.clear_operation_mode
con.power_off
con.disconnect
