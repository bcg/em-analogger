require File.dirname(__FILE__) + '/../lib/em-analogger'
require "tempfile"
require "swiftcore/Analogger"
require "em-spec/rspec"

class LogFile < EM::Connection
  include EM::Deferrable

  def post_init
    @messages  = []
  end

  def notify_readable
    begin
      loop do
        data = @io.readline
        @messages << data.rstrip if data
      end
    rescue EOFError
      set_deferred_status :succeeded if @messages.size > 0
      true
    end
  end

  def pop(&blk)
    callback {
      data = @messages.pop
      raise "Failed to pop log message" if not data
      date, service, level, message = data.split('|')
      yield date, service, level, message
    }
  end

end

module EM
  module Spec
    module Analogger
      extend EM::SpecHelper 

      @@logfile = Tempfile.new('analogger.')
      @@tmpio = nil
      @@log = nil

      def self.logfile
        @@log
      end

      def self.shutdown_reactor
        done
      end

      def self.server_conf
        config={}
        config[Swiftcore::Analogger::Cport] = 6766
        config[Swiftcore::Analogger::Cdefault_log] = @@logfile
        config[Swiftcore::Analogger::Csyncinterval] = 1
        config[Swiftcore::Analogger::Cinterval] = 1 
        config
      end

      def self.server(start_server = true)
        File.open(@@logfile, File::TRUNC|File::CREAT).close
        @@tmpfd = IO.sysopen(@@logfile)
        em do
          Swiftcore::Analogger.start(self.server_conf) if start_server

          @@log = EM.watch(IO.for_fd(@@tmpfd), LogFile)
          @@log.notify_readable = true

          analogger = EM::Analogger.new

          EM.next_tick do
            yield analogger
          end
        end
      end

    end
  end
end

