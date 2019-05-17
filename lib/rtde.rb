require_relative 'serialize'
require 'socket'
require 'logger'
require 'uri'

module UR

  class Rtde
    PROTOCOL_VERSION = 2

    module Command #{{{
      RTDE_REQUEST_PROTOCOL_VERSION = 86        # ASCII V
      RTDE_GET_URCONTROL_VERSION = 118          # ASCII V
      RTDE_TEXT_MESSAGE = 77                    # ASCII M
      RTDE_DATA_PACKAGE = 85                    # ASCII U
      RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS = 79   # ASCII O
      RTDE_CONTROL_PACKAGE_SETUP_INPUTS = 73    # ASCII I
      RTDE_CONTROL_PACKAGE_START = 83           # ASCII S
      RTDE_CONTROL_PACKAGE_PAUSE = 80           # ascii p
    end #}}}
    module ConnectionState #{{{
      DISCONNECTED = 0
      CONNECTED = 1
      STARTED = 2
      PAUSED = 3
    end #}}}

    def initialize(host, logger=Logger.new(STDOUT,level: :INFO)) #{{{
      host = '//' + host if host !~ /\/\//
      uri = URI::parse(host)
      @logger = logger
      @hostname = uri.host
      @port = uri.port.nil? ? 30004 : uri.port
      @conn_state = ConnectionState::DISCONNECTED
      @sock = nil
      @output_config = nil
      @input_config = {}
    end #}}}

    def connect #{{{
      return if @sock

      @buf = '' # buffer data in binary format
      begin
        @sock = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
        @sock.setsockopt Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1
        @sock = TCPSocket.new(@hostname, @port)
        @conn_state = ConnectionState::CONNECTED
      rescue
        @sock = nil
        raise
      end
      if not negotiate_protocol_version
        raise RuntimeError.new 'Unable to negotiate protocol version'
      end
      self
    end #}}}

    def disconnect #{{{
      if @sock
        @sock.close
        @sock = nil
        @conn_state = ConnectionState::DISCONNECTED
        @logger.info "Connection closed " + @hostname +":" + @port.to_s
        true
      else
        false
      end
    end #}}}

    def connected? #{{{
      @conn_state != ConnectionState::DISCONNECTED
    end #}}}

    def controller_version #{{{
      cmd = Command::RTDE_GET_URCONTROL_VERSION
      version = send_and_receive cmd
      @logger.debug 'Controller Version: ' + version.major.to_s + '.' + version.minor.to_s + '.' + version.bugfix.to_s + '.' + version.build.to_s
      if version
        if version.major == 3 && version.minor <=2 && version.bugfix < 19171
          @logger.error 'Upgrade your controller to version higher than 3.2.19171'
          exit
        end
        [version.major, version.minor, version.bugfix, version.build]
      else
        [nil, nil, nil, nil]
      end
    end #}}}

    def negotiate_protocol_version #{{{
      cmd = Command::RTDE_REQUEST_PROTOCOL_VERSION
      payload = [PROTOCOL_VERSION].pack 'S>'
      send_and_receive cmd, payload
    end #}}}

    def send(input_data) #{{{
      if @conn_state != ConnectionState::STARTED
        @logger.error 'Cannot send when RTDE synchroinization is inactive'
        return
      end
      if not @input_config.key?(input_data.recipe_id)
        @logger.error 'Input configuration id not found: ' + @input_data.recipe_id
        return
      end
      config = @input_config[input_data.recipe_id]
      send_all Command::RTDE_DATA_PACKAGE, config.pack(input_data)
    end #}}}
    def send_and_receive(cmd, payload = '') #{{{
      @logger.debug 'Start send_and_receive'
      send_all(cmd, payload) ? recv(cmd) : nil
    end #}}}
    def send_all(command, payload = '') #{{{
      fmt = 'S>C'
      size = ([0,0].pack fmt).length + payload.length
      buf = [size, command].pack(fmt) + payload
      @logger.debug 'send_all.size: ' +size.to_s
      @logger.debug 'send_all.buf: ' + buf.to_s + "\n"
      if !@sock
        @logger.error 'Unable to send: not connected to Robot'
        return false
      end

      _, writable, _ = IO.select([], [@sock], [])
      if writable.length > 0
        #@logger.debug 'buffer: ' + buf
        @sock.sendmsg(buf)
        @logger.debug 'sending ok'
        true
      else
        trigger_disconnected
        false
      end
    end #}}}
    def send_message(message, source = 'Ruby Client', type = Serialize::Message::INFO_MESSAGE) #{{{
      cmd = Command::RTDE_TEXT_MESSAGE
      fmt = 'Ca%dCa%dC' % [message.length, source.length]
      payload = struct.pack(fmt, message.length, message, source.length, source, type)
      send_all(cmd, payload)
    end #}}}
    def send_start #{{{
      @logger.debug 'Start send_start'
      cmd = Command::RTDE_CONTROL_PACKAGE_START
      if send_and_receive cmd
        @logger.info 'RTDE synchronization started'
        @conn_state = ConnectionState::STARTED
        true
      else
        @logger.error 'RTDE synchronization failed to start'
        false
      end
    end
 #}}}
    def send_pause #{{{
      cmd = Command::RTDE_CONTROL_PACKAGE_PAUSE
      success = send_and_receive(cmd)
      if success
        @logger.info 'RTDE synchronization paused'
        @conn_state = ConnectionState::PAUSED
      else
        @logger.error('RTDE synchronization failed to pause')
      end
      success
    end #}}}
    def send_input_setup(variables, types=[]) #{{{
      cmd = Command::RTDE_CONTROL_PACKAGE_SETUP_INPUTS
      payload = variables.join ','
      result = send_and_receive cmd, payload
      if types.length != 0 && result.types != types
        @logger.error(
          'Data type inconsistency for input setup: ' +
          types.to_s + ' - ' +
          result.types.to_s
        )
        return nil
      end

      result.names = variables
      @input_config[result.id] = result
      Serialize::DataObject.create_empty variables, result.id
    end #}}}
    def send_output_setup(variables, types=[], frequency = 125) #{{{
      @logger.debug 'Start send_output_setup'
      @logger.debug 'variables: ' + variables.to_s
      @logger.debug 'types: ' + types.to_s + "\n"
      cmd = Command::RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS
      payload = [frequency].pack 'G'
      payload = payload + variables.join(',')
      result = send_and_receive cmd, payload
      if types.length != 0 && result.types != types
        @logger.error(
          'Data type inconsistency for output setup: ' +
          types.to_s + ' - ' +
          result.types.to_s
        )
        return false
      end
      result.names = variables
      @output_config = result
      @logger.debug 'result:' + @output_config.to_s
      return true
    end #}}}

    def receive #{{{
      @logger.debug 'Start receive'
      if !@output_config
        @logger.error 'Output configuration not initialized'
        nil
      end
      return nil if @conn_state != ConnectionState::STARTED
      recv Command::RTDE_DATA_PACKAGE
    end #}}}
    def recv(command) #{{{
      @logger.debug 'Start recv' + @buf.to_s
      while connected?
        readable, _, xlist = IO.select([@sock], [], [@sock])
        @logger.debug 'Readable: ' + readable.to_s
        if readable.length > 0
          @logger.debug 'readable.length >0: ' + readable.length.to_s
          more = @sock.recv(4096)
          if more.length == 0
            trigger_disconnected
            return nil
          end
          @buf += more
        end

        if xlist.length > 0 || readable.length == 0
          @logger.info 'lost connection with controller'
          trigger_disconnected
          return nil
        end
        while @buf.length >= 3
          @logger.debug '@buf>=3'
          packet_header = Serialize::ControlHeader.unpack(@buf)

          if @buf.length >= packet_header.size
            @logger.debug '@buf.length >= packet_header.size' + @buf.length.to_s + ">=" + packet_header.size.to_s
            packet, @buf = @buf[3..packet_header.size], @buf[packet_header.size..-1]
            #@logger.debug 'Packet:' + packet.to_s
            @logger.debug 'Packet_Header_Command: ' + packet_header.command.to_s + "\n"
            data = on_packet(packet_header.command, packet)
            @logger.debug 'DATA:' + data.to_s
            if @buf.length >= 3 && command == Command::RTDE_DATA_PACKAGE
              @logger.debug '@buf.length >= 3 && command == Command::RTDE_DATA_PACKAGE'
              next_packet_header = Serialize::ControlHeader.unpack(@buf)
              if next_packet_header.command == command
                @logger.info 'skipping package(1)'
                next
              end
            end
            if packet_header.command == command
              @logger.debug 'returning becuase of packet_header.command == command'
              return data
            else
              @logger.info 'skipping package(2)'
            end
          else
            break
          end
        end
      end
      nil
    end #}}}

    def on_packet(cmd, payload) #{{{
      return unpack_protocol_version_package(payload)     if cmd == Command::RTDE_REQUEST_PROTOCOL_VERSION
      return unpack_urcontrol_version_package(payload)    if cmd == Command::RTDE_GET_URCONTROL_VERSION
      return unpack_text_message(payload)                 if cmd == Command::RTDE_TEXT_MESSAGE
      return unpack_setup_outputs_package(payload)        if cmd == Command::RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS
      return unpack_setup_inputs_package(payload)         if cmd == Command::RTDE_CONTROL_PACKAGE_SETUP_INPUTS
      return unpack_start_package(payload)                if cmd == Command::RTDE_CONTROL_PACKAGE_START
      return unpack_pause_package(payload)                if cmd == Command::RTDE_CONTROL_PACKAGE_PAUSE
      return unpack_data_package(payload, @output_config) if cmd == Command::RTDE_DATA_PACKAGE
      @logger.error 'Unknown package command' + cmd.to_s
    end #}}}

    def has_data? #{{{
      timeout = 0
      readable, _, _ = IO.select([@sock], [], [], timeout)
      readable.length != 0
    end #}}}

    def trigger_disconnected #{{{
      @logger.info 'RTDE disconnected'
      disconnect
    end #}}}

     def unpack_protocol_version_package(payload) #{{{
       @logger.debug 'unpaking protocol version package'
       return nil if payload.length != 1
       Serialize::ReturnValue.unpack(payload).success
     end #}}}
     def unpack_urcontrol_version_package(payload) #{{{
       @logger.debug 'unpack urcontrol_version'
       return nil if payload.length != 16
       @logger.debug 'packet lenght ok'
       Serialize::ControlVersion.unpack payload
     end #}}}
     def unpack_text_message(payload) #{{{
       return nil if payload.length < 1
       msg = Serialize::Message.unpack payload
       @logger.error  (msg.source + ':' + msg.message) if msg.level == Serialize::Message::EXCEPTION_MESSAGE || msg.level == Serialize::Message::ERROR_MESSAGE
       @logger.warning(msg.source + ':' + msg.message) if msg.level == Serialize::Message::WARNING_MESSAGE
       @logger.info   (msg.source + ':' + msg.message) if msg.level == Serialize::Message::INFO_MESSAGE
     end #}}}
     def unpack_setup_outputs_package(payload) #{{{
       @logger.debug 'Start unpack_setup_outputs_package'
       if payload.length < 1
         @logger.error 'RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS: No payload'
         return nil
       end
       @logger.debug 'Payload for unpack: ' + payload.to_s
       Serialize::DataConfig.unpack_recipe payload
     end #}}}
     def unpack_setup_inputs_package(payload) #{{{
       if payload.length < 1
         @logger.error 'RTDE_CONTROL_PACKAGE_SETUP_INPUTS: No payload'
         return nil
       end
       Serialize::DataConfig.unpack_recipe payload
     end #}}}
     def unpack_start_package(payload) #{{{
       if payload.length != 1
         @logger.error 'RTDE_CONTROL_PACKAGE_START: Wrong payload size'
         return nil
       end
       Serialize::ReturnValue.unpack(payload).success
     end #}}}
     def unpack_pause_package(payload) #{{{
       if payload.length != 1
         @logger.error 'RTDE_CONTROL_PACKAGE_PAUSE: Wrong payload size'
         return nil
       end
       Serialize::ReturnValue.unpack(payload).success
     end #}}}
     def unpack_data_package(payload, output_config) #{{{
       if !output_config
         @logger.error 'RTDE_DATA_PACKAGE: Missing output configuration'
         return nil
       end
       @logger.debug "outputconfig: " + output_config.to_s
       @logger.debug "payload: " + payload.to_s
       output_config.unpack payload
     end #}}}

  end

end
