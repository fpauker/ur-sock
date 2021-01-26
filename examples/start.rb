#!/usr/bin/env ruby
require_relative '../lib/psi'

con = UR::Psi.new('192.168.56.104').connect
con.execute_ur_script(File.join(__dir__,'start.script'))
con.disconnect
