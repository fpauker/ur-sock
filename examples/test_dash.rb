#!/usr/bin/env ruby
require_relative '../lib/ur-sock'
#require 'ur-sock'
require_relative 'dashboard'

con     = UR::Dash.new('localhost').connect

puts "Robotmode: " + con.get_robotmode
if con.get_robotmode != UR::Dash::ProgramState::RUNNING
  con.start_program
  sleep 10
end
con.get_loaded_program
con.pause_program
sleep 5
con.start_program
con.get_robotmode
sleep 5
con.stop_program
con.disconnect
