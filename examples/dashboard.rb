#!/usr/bin/env ruby
require 'socket'        # Sockets are in standard library
require 'logger'
require 'uri'

module UR

  class Dash
    module ConnectionState
      DISCONNECTED = 0
      CONNECTED = 1
      STARTED = 2
      PAUSED = 3
    end

    module ProgramState
      NO_CONTROLLER =   "NO_CONTROLLER"
      DISCONNECTED =    "DISCONNECTED"
      CONFIRM_SAFETY =  "CONFIRM_SAFETY"
      BOOTING =         "BOOTING"
      POWER_OFF =       "POWER_OFF"
      POWER_ON =        "POWER_ON"
      IDLE =            "IDLE"
      BACKDRIVE =       "BACKDRIVE"
      RUNNING =         "RUNNING"
    end

    def initialize(host, logger=Logger.new(STDOUT,level: :INFO))
      host = '//' + host if host !~ /\/\//
      uri = URI::parse(host)
      @logger = logger
      @hostname = uri.host
      @port = uri.port.nil? ? 29999 : uri.port
      @conn_state = ConnectionState::DISCONNECTED
      @sock = nil
    end

    def connect
      return if @sock
      @sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
      @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
      @sock = TCPSocket.new(@hostname, @port)
      @conn_state = ConnectionState::CONNECTED
      @logger.info @sock.gets
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
        @logger.info "Connection closed " + @hostname + ":" + @port.to_s
      end
    end

    def start_program
      @sock.write("play\n")
      line = @sock.gets
      if line == "Starting program"
        @logger.info line
      else
        @logger.error line
      end
    end

    def pause_program
      @sock.write("pause\n")
      @logger.info "paused program"
      @logger.info @sock.gets
    end

    def stop_program
      @sock.write("stop\n")
      @logger.info "stopped program"
      @logger.info @sock.gets
    end

    def get_robotmode
      @sock.write("robotmode\n")
      line = @sock.gets
      @logger.info line
      result = $1.strip if line.match(/^Robotmode:\s(.+)/)
    end

    def get_loaded_program
      @sock.write ("get loaded program\n")
      line = @sock.gets
      @logger.info line
      path = $1.strip if line.match(/^Loaded program:\s(.+)/)
    end
  end

end
