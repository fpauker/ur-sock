#!/usr/bin/env ruby
require 'socket'        # Sockets are in standard library
require 'logger'
require 'uri'

module UR

  class Psi
    module ConnectionState
      DISCONNECTED = 0
      CONNECTED = 1
      STARTED = 2
      PAUSED = 3
    end

    def initialize(host, logger=Logger.new(STDOUT,level: :INFO))
      host = '//' + host if host !~ /\/\//
      uri = URI::parse(host)
      @logger = logger
      @hostname = uri.host
      @port = uri.port.nil? ? 30003 : uri.port
      @conn_state = ConnectionState::DISCONNECTED
      @sock = nil
    end

    def connect
      return if @sock
      @sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
      @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
      @sock = TCPSocket.new(@hostname, @port)
      @conn_state = ConnectionState::CONNECTED
      self
    end

    def connected?
      @conn_state != ConnectionState::DISCONNECTED
    end

    def disconnect
      if @sock
        @sock.close
        @sock = nil
        @conn_state = ConnectionState::DISCONNECTED
        @logger.info 'Connection closed ' + @hostname + ':' + @port.to_s
      end
    end

    def execute_ur_script_file(filename)
      @logger.info 'Executing UR Script File: ' + filename
      File.open(filename) do |file|
        while not file.eof?
          @sock.write(file.readline)
          line = @sock.gets.strip
          @logger.debug line
        end
      end
    end

    def execute_ur_script(str)
      @logger.info 'Executing UR Script ...'
      @sock.write(str)
      line = @sock.gets.strip
      @logger.debug line
    end
  end

end
