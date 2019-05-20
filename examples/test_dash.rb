#!/usr/bin/env ruby
require_relative '../lib/ur-sock'
#require 'ur-sock'
require_relative 'dashboard'

con     = UR::Dash.new('192.168.56.101').connect
puts con.connected?
con.robotmode
con.play
sleep 10
con.pause
sleep 5
con.play
con.robotmode
sleep 5
con.stop
### Set Speed to very slow
# speed_names, speed_types = conf.get_recipe('speed')
# speed = con.send_input_setup(speed_names, speed_types)
# speed["speed_slider_mask"] = 1
# speed["speed_slider_fraction"] = 0
# con.send(speed)
con.disconnect
