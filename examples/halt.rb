#!/usr/bin/env ruby
require_relative '../lib/transfer'

con = Psi.new('localhost').connect
con.transfer(File.join(__dir__,'halt.script'))
con.disconnect
