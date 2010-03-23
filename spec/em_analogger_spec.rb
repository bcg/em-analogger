require File.dirname(__FILE__) + '/spec_helper.rb'

describe EM::Analogger do

  it 'should log messages' do
    EM::Spec::Analogger.server_start do |client|
      client.log "info", "test", true
      EM::Spec::Analogger.log.pop do |date, service, level, message|
        message.should == "test"
        EM::Spec::Analogger.close
      end
    end
  end

end

