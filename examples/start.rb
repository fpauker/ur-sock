#!/usr/bin/env ruby
require_relative '../lib/transfer'

con = Psi.new('localhost').connect
con.transfer(File.join(__dir__,'start.script'))
con.disconnect
