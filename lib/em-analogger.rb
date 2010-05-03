require 'rubygems'
require 'eventmachine'

module EventMachine
  module Analogger
    VERSION     = '0.1.1'
    DEF_IP      = '127.0.0.1'
    DEF_PORT    = 6766
    
    def self.new(service = 'default', host = DEF_IP, port = DEF_PORT, opts = {}) 
      EventMachine::Analogger::Connection.connect(service, host, port, opts)
    end

    class Connection < EventMachine::Connection
      Cauthentication = 'authentication'.freeze
      Ci = 'i'.freeze

      attr_accessor :key, :host, :port, :buffer, :connected, :sender,
                    :reconnect_in

      def self.connect(service = 'default', host = '127.0.0.1', port = 6766, opts = {})
        connection = ::EventMachine.connect(host, port.to_i, self) do |conn|
          conn.connected    = false
          conn.buffer     ||= ''
          conn.service      = service
          conn.host         = host
          conn.port         = port
          conn.key          = opts[:key]
          conn.reconnect_in = opts[:reconnect_in] || 2
        end
      end
      
      def connection_completed
        @connected = true
        log(Cauthentication,"#{@key}",true)
        send_data @buffer
      end

      def service
        @service
      end

      def service=(val)
        @service = val
        @service_length = val.length
      end

      def close
        close_connection_after_writing
      end

      def closed?
        @connected
      end

      def unbind
        @connected = false
        EM.add_timer(@reconnect_in) { reconnect(@host, @port) }
      end

      def log(severity, msg, immediate = false)
        len = [@service_length + severity.length + msg.length + 3].pack(Ci)
        fullmsg = "#{len}#{len}:#{@service}:#{severity}:#{msg}"
        if immediate
          send_data fullmsg
        elsif @connected
          send_data fullmsg
        else
          @buffer << fullmsg
        end
      rescue Exception => e
        puts e
        @buffer << fullmsg if msg and severity
        false
      end

      def send_data(data)
        super(data)
      end
    end

  end
end

