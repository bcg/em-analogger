require File.dirname(__FILE__) + '/spec_helper.rb'

describe EM::Analogger do

  it 'should log a message' do
    EM::Spec::Analogger.server(true) do |client|
      client.log("info", "test", true)
      EM::Spec::Analogger.logfile.pop do |date, service, level, message|
        message.should == "test"
        EM::Spec::Analogger.shutdown_reactor
      end
    end
  end

  it 'should buffer log messages until the server comes online' do
    EM::Spec::Analogger.server(false) do |client|
      client.log("info", "test1")
      client.log("info", "test2")

      Swiftcore::Analogger.start(EM::Spec::Analogger.server_conf)

      EM::Spec::Analogger.logfile.pop do |date, service, level, message|
        message.should == "test2"
      end
      EM::Spec::Analogger.logfile.pop do |date, service, level, message|
        message.should == "test1"
        EM::Spec::Analogger.shutdown_reactor
      end
    end
  end

end

