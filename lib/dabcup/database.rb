require 'open3'

module Dabcup
  class Database
    attr_reader :name
    attr_reader :config
    attr_reader :main_storage
    attr_reader :spare_storage
    
    def initialize(name, config)
      @name = name
      @config = config
      @main_storage = Dabcup::Storage.new(config['storage'])
      @spare_storage = Dabcup::Storage.new(config['spare_storage']) if config['spare_storage']
      extend(Tunnel) if tunnel
    end

    def tunnel
      @tunnel ||= Addressable::URI.parse(config['tunnel']) if config['tunnel']
    end

    def via_ssh?
      tunnel != nil
    end
    
    def dump(dump_path)
      system(config['dump'], :dump_path => File.expand_path(dump_path))
    end
    
    def system(command, interpolation = {})
      command = command % interpolation
      Dabcup::info(command)
      # TODO Found a nice way to get the exit status.
      stdin, stdout, stderr = Open3.popen3(command + "; echo $?")
      Dabcup::info(stdout.read) if not stdout.eof?
      raise Dabcup::Error.new("Failed to execute '#{command}', stderr is '#{stderr.read}'.") if not stderr.eof?
      [stdin, stdout, stderr]
    end
  end

  module Tunnel
    def system(command, interpolation = {})
      command = command % interpolation
      Dabcup::info("SSH #{tunnel} '#{command}'")
      stdout = ssh.exec!(command)
      Dabcup::info(stdout)
    end
    
    def ssh
      @ssh ||= Net::SSH.start(tunnel.host, tunnel.user, :password => tunnel.password)
    end
    
    def disconnect
      @ssh.close if @ssh
    end
  end
end

