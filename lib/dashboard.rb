#!/usr/bin/env ruby
require 'socket'        # Sockets are in standard library
require 'logger'
require 'uri'
require 'socketry'

module UR

  class Dash
    module ConnectionState
      DISCONNECTED = 'DISCONNECTED'
      CONNECTED = 'CONNECTED'
      STARTED = 'STARTED'
      PAUSED = 'PAUSED'
    end

    module ProgramState
      STOPPED = 'STOPPED'
      PLAYING ='PLAYING'
      PAUSED = 'PAUSED'
    end

    module SafetyMode
      NORMAL = "NORMAL"
      REDUCED = "REDUCED"
      PROTECTIVE_STOP = "PROTECTIVE_STOP"
      RECOVERY = "RECOVERY"
      SAFEGUARD_STOP = "SAFEGUARD_STOP"
      SYSTEM_EMERGENCY_STOP = "SYSTEM_EMERGENCY_STOP"
      ROBOT_EMERGENCY_STOP = "ROBOT_EMERGENCY_STOP"
      VIOLATION = "VIOLATION"
      FAULT = "FAULT"
    end

    module ProgramState
      NO_CONTROLLER =   'NO_CONTROLLER'
      DISCONNECTED =    'DISCONNECTED'
      CONFIRM_SAFETY =  'CONFIRM_SAFETY'
      BOOTING =         'BOOTING'
      POWER_OFF =       'POWER_OFF'
      POWER_ON =        'POWER_ON'
      IDLE =            'IDLE'
      BACKDRIVE =       'BACKDRIVE'
      RUNNING =         'RUNNING'
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
      #@sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
      #@sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
      #@sock = TCPSocket.new(@hostname, @port)
      @sock = Socketry::TCP::Socket.connect(@hostname, @port)
      p @sock.read_timeout
      @conn_state = ConnectionState::CONNECTED
      @logger.info @sock.readpartial(1024).strip
      self
    end

    def connected?
      @conn_state != ConnectionState::DISCONNECTED
    end

    def reconnect

    end

    def disconnect
      if @sock
        @sock.close
        @sock = nil
        @conn_state = ConnectionState::DISCONNECTED
        @logger.info "Connection closed " + @hostname + ":" + @port.to_s
      end
    end

    def load_program (programname)
      @logger.debug "loadprogram"
      send = "load " + programname + ".urp\n"
      puts send
      @sock.write (send)
      line = @sock.gets.strip
      if line.match(/^./) == 'L'
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def start_program
      @sock.write("play\n")
      line = @sock.gets.strip
      if line == "Starting program"
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def stop_program
      @sock.write("stop\n")
      line = @sock.gets.strip
      if line == "Stopped"
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def pause_program
      @sock.write("pause\n")
      line = @sock.gets.strip
      if line == "Pausing program"
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def shutdown
      @sock.write("shutdown\n")
      line = @sock.gets.strip
      if line == "Shutting down"
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def running?
      @sock.write("running\n")
      line = @sock.gets.strip
      if line == "Program running: True"
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def get_robotmode
      @sock.write("robotmode\n")
      line = @sock.gets.strip
      @logger.debug line
      result = $1.strip if line.match(/^Robotmode:\s(.+)/)
    end

    def get_loaded_program
      @sock.write ("get loaded program\n")
      line = @sock.readpartial(1024).strip
      if line.match(/^Loaded program:\s(.+)/)
        @logger.debug line
        path = $1.strip
      else
        @logger.error line
        nil
      end
    end

    def open_popupmessage(message)
      @sock.write ("popup " + message.to_s + "\n")
      @logger.debug @sock.gets.strip
    end

    def close_popupmessage
      @sock.write ("close popup\n")
      @logger.debug @sock.gets.strip
    end

    def add_to_log(message)
      @sock.write ("addToLog " + message.to_s + "\n")
      line = @sock.gets.strip
      if line.match(/^Added log message/)
        @logger.debug line
      else
        @logger.error line
      end
    end

    def is_program_saved?
      @sock.write("isProgramSaved\n")
      line = @sock.gets.strip
      if line == "True"
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def get_program_state
      @sock.write("programState\n")
      line = @sock.readpartial(1024).strip
      @logger.debug line
      line
    end

    def get_polyscope_version
      @sock.write("PolyscopeVersion\n")
      line = @sock.gets.strip
      @logger.debug line
      line
    end

    def set_operation_mode_manual
      @sock.write("set operational mode manual\n")
      line = @sock.gets.strip
      if line.match(/^S/)
        @logger.debug line
      else
        @logger.error line
      end
    end

    def set_operation_mode_auto
      @sock.write("set operational mode automatic\n")
      line = @sock.gets.strip
      if line.match(/^S/)
        @logger.debug line
      else
        @logger.error line
      end
    end

    def clear_operation_mode
      @sock.write("clear operational mode\n")
      line = @sock.gets.strip
      if line.match(/^operational/)
        @logger.debug line
        true
      else
        @logger.error line
      end
    end

    def power_on
      @sock.write("power on\n")
      line = @sock.gets.strip
      if line.match(/^Powering/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def power_off
      @sock.write("power off\n")
      line = @sock.gets.strip
      if line.match(/^Powering/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def break_release
      @sock.write("brake release\n")
      line = @sock.gets.strip
      if line.match(/^Brake/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def get_safety_mode
      @sock.write("safetymode\n")
      line = @sock.gets.strip
      @logger.debug line
      result = $1.strip if line.match(/^Safetymode:\s(.+)/)
    end

    def unlock_protective_stop
      @sock.write("unlock protective stop\n")
      line = @sock.gets.strip
      if line.match(/^Protective/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def close_safety_popup
      @sock.write("close safety popup\n")
      line = @sock.gets.strip
      if line.match(/^closing/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def load_installation
      @sock.write("load installation\n")
      line = @sock.gets.strip
      if line.match(/^Loading/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

    def restart_safety
      @sock.write("restart safety\n")
      line = @sock.gets.strip
      if line.match(/^Brake/)
        @logger.debug line
        true
      else
        @logger.error line
        nil
      end
    end

  end
end
