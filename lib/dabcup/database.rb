require 'open3'

module Dabcup::Database
  class Base
    attr_accessor :host
    attr_accessor :port
    attr_accessor :login
    attr_accessor :password
    attr_accessor :database

    def initialize(config)
      @host = config['host']
      @port = config['port']
      @login = config['login']
      @password = config['password']
      @database = config['name']
    end
    
    def default_port(port)
      @port = port if @port.nil? or @port.empty?
    end
    
    def dump(file_path)
      raise NotImplementedError('Sorry.')
    end
    
    def restore(file_path)
      raise NotImplementedError('Sorry.')
    end
    
    def system(command)
      Dabcup::info(command)
      # TODO Found a nice way to get the exit status.
      stdin, stdout, stderr = Open3.popen3(command + "; echo $?")
      Dabcup::info(stdout.read) if not stdout.eof?
      raise Dabcup::Error.new("Failed to execute '#{command}', stderr is '#{stderr.read}'.") if not stderr.eof?
    end
  end

  class Factory
    def self.new_database(db_config)
      adapter = db_config['adapter']
      case adapter
      when 'PostgreSQL'
        @db = Dabcup::Database::PostgreSQL.new(db_config)
      when 'MySQL'
        @db = Dabcup::Database::MySQL.new(db_config)
      else
        raise "Unknow '#{adapter}' database adapter"
      end
    end
  end

  class PostgreSQL < Base
    def initialize(config)
      super(config)
      default_port(5432)
    end

    # TODO sanitize parameters
    def dump(file_path)
      system("pg_dump -Fc -h #{@host} -p #{@port} -U #{@login} -f #{file_path} #{@database}")
    end

    def restore(file_path)
      system("pg_restore -Fc -c -O -h #{@host} -p #{@port} -U #{@login} -d #{@database} #{file_path}")
    end
  end
  
  class MySQL < Base
    def initialize(config)
      super(config)
      default_port(3306)
    end
    
    def dump(file_path)
      system("mysqldump -h #{@host} -P #{@port} -u #{@login} -r #{file_path} #{@database}")
    end
    
    def restore(file_path)
      system("mysql -h #{@host} -P #{@port} -u #{@login} #{@database} < #{file_path}")
    end
  end
  
  def self.dump_name(database, time = Time.now)
    database.database + '_' + Dabcup::time_to_name(time)
  end
end
