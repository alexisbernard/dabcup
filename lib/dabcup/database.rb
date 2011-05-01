require 'open3'

module Dabcup
  class Database
    attr_reader :name
    attr_reader :config
    attr_reader :database
    attr_reader :main_storage
    attr_reader :spare_storage
    
    def initialize(name, config)
      @name = name
      @config = config
      @main_storage = Dabcup::Storage.new(config['storage'])
      @spare_storage = Dabcup::Storage.new(config['spare_storage']) if config['spare_storage']
    end

    def initialize_ssh
      if @config['ssh']
        extend(SSH)
        @ssh_host = @config['ssh']['host']
        @ssh_login = @config['ssh']['login']
        @ssh_password = @config['ssh']['password']
      end
    end
    
    def via_ssh?
      config['ssh'] != nil
    end
    
    def dump(dump_path)
      system(config['database']['dump'], :dump_path => File.expand_path(dump_path))
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

  module SSH
    attr_reader :ssh
    
    def system(command)
      Dabcup::info("SSH #{ssh_login}@#{ssh_host} '#{command}'")
      stdout = ssh.exec!(command)
      Dabcup::info(stdout)
    end
    
    def ssh
      connect if not @ssh
      @ssh
    end
    
    def connect
      @ssh = Net::SSH.start(ssh_host, ssh_login, :password => ssh_password)
    end
    
    def disconnect
      @ssh.close if @ssh
    end
  end
end

