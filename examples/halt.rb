#!/usr/bin/env ruby
require_relative '../lib/transfer'

con = Transfer.new('localhost').connect
con.transfer(File.join(__dir__,'halt.script'))
con.disconnect
