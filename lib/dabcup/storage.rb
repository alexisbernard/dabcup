require 'net/ftp'
require 'fileutils'

module Dabcup::Storage
  class Base
    attr_accessor :host
    attr_accessor :port
    attr_accessor :login
    attr_accessor :password
    attr_accessor :path

    def initialize(config)
      @host = config['host']
      @port = config['port']
      @login = config['login']
      @password = config['password']
      @path = config['path']
    end
    
    def default_port(port)
      @port = port if @port.nil? or @port.empty?
    end
    
    # Connects to remote host.
    def connect
      raise NotImplementedError.new('Sorry.')
    end
    
    # Disconnects from remote host.
    def disconnect
      raise NotImplementedError.new('Sorry.')
    end
    
    def put
      raise NotImplementedError.new('Sorry.')
    end
    
    def get
      raise NotImplementedError.new('Sorry.')
    end
    
    def list
      raise NotImplementedError.new('Sorry.')
    end
    
    def delete
      raise NotImplementedError.new('Sorry.')
    end
    
    def exists?(name)
      list.each do |dump|
        return true if dump.name == name
      end
      false
    end
    
    def dump_name?(name)
      return false
    end
  end

  class Factory
    @@storages_config = {}
    
    def self.storages_config=(storages_config)
      return if not storages_config
      if not storages_config.is_a?(Hash)
        raise ArgumentError.new("Hash expected, not a '#{storages_config.class}'")
      end
      @@storages_config = storages_config
    end
    
    def self.new_storage(hash_or_string)
      case hash_or_string
      when Hash
        new_storage_from_adapter(hash_or_string)
      when String
        new_storage_from_name(hash_or_string)
      else
        raise ArgumentError.new("Hash or String expected, not '#{hash_or_string.class}'.")
      end
    end
    
    # Returns a derived Storage instance of the relevant type.
    def self.new_storage_from_adapter(storage_config)
      adapter = storage_config['adapter']
      case adapter
      when 'S3':
        @storage = Dabcup::Storage::S3.new(storage_config)
      when 'FTP':
        @storage = Dabcup::Storage::FTP.new(storage_config)
      when 'SFTP':
        @storage = Dabcup::Storage::SFTP.new(storage_config)
      when 'LOCAL'
        @storage = Dabcup::Storage::LOCAL.new(storage_config)
      else
        raise Dabcup::Error.new("Unknow '#{adapter}' storage adapter.")
      end
    end
    
    def self.new_storage_from_name(name)
      config = @@storages_config[name]
      raise Dabcup::Error.new("Unkown '#{name}' storage name.") if not config
      new_storage_from_adapter(config)
    end
  end
  
  # Amazon S3
  class S3 < Base
    def initialize(config)
      super(config)
      require 'aws/s3'
      @bucket = config['bucket']
    rescue LoadError => ex
      raise Dabcup::Error.new("The library aws-s3 is missing. Get it via 'gem install aws-s3'")
    end

    def put(local_path, remote_path)
      connect
      Dabcup::info("S3 put #{local_path} to #{@bucket}:#{remote_path}")
      File.open(local_path) do |file|
        AWS::S3::S3Object.store(remote_path, file, @bucket)
      end
    end

    def get(remote_path, local_path)
      connect
      Dabcup::info("S3 get #{local_path} from #{@bucket}:#{remote_path}")
      File.open(local_path, 'w') do |file|
        AWS::S3::S3Object.stream(remote_path, @bucket) do |stream|
          file.write(stream)
        end
      end
    end
    
    def list
      connect
      Dabcup::info("S3 list #{@bucket}")
      AWS::S3::Bucket.find(@bucket).objects.collect do |obj|
        # AWS returns a Time object if string is like: YYYY-MM-DDTHH:mm.
        name = obj.key.is_a?(Time) ? Dabcup::time_to_name(obj.key) : obj.key.to_s
        Dump.new(:name => name, :size => obj.size)
      end
    end
    
    def delete(file_names)
      connect
      file_names = [file_names] if file_names.kind_of?(String)
      file_names.each do |file_name|
        Dabcup::info("S3 delete #{@bucket}:#{file_name}")
        AWS::S3::S3Object.delete(file_name, @bucket)
      end
    end
    
    def connect
      return if AWS::S3::Base.connected?
      Dabcup::info("S3 connect to amazon")
      AWS::S3::Base.establish_connection!(:access_key_id => @login, :secret_access_key => @password)
    end
    
    def disconnect
      Dabcup::info("S3 disconnect from amazon")
      AWS::S3::Base.disconnect!
    end
  end
  
  # FTP
  class FTP < Base
    def initialize(config)
      super(config)
      default_port(21)
    end
    
    def put(local_path, remote_name)
      connect
      remote_path = File.join(@path, remote_name)
      Dabcup::info("FTP put #{local_path} to #{@login}@#{@host}:#{remote_path}")
      @ftp.putbinaryfile(local_path, remote_path)
    end
    
    def get(remote_name, local_path)
      connect
      remote_path = File.join(@path, remote_name)
      Dabcup::info("FTP get #{local_path} from #{@login}@#{@host}:#{remote_path}")
      @ftp.getbinaryfile(remote_path, local_path)
    end
    
    def list
      connect
      dumps = []
      Dabcup::info("FTP list #{@login}@#{@host}:#{@path}")
      lines = @ftp.list(@path)
      lines.collect do |str|
        fields = str.split(' ')
        next if fields[8] == '.' or fields[8] == '..'
        dumps << Dabcup::Storage::Dump.new(:name => fields[8], :size => fields[4].to_i)
      end
      dumps
    end
    
    def delete(file_names)
      connect
      file_names = [file_names] if file_names.kind_of?(String)
      file_names.each do |file_name|
        file_path = File.join(@path, file_name)
        Dabcup::info("FTP delete #{@login}@#{@host}:#{file_path}")
        @ftp.delete(file_path)
      end
    end
    
    def connect
      return if @ftp
      Dabcup::info("FTP connect to #{@login}@#{@host}")
      @ftp = Net::FTP.new
      @ftp.connect(@host, @port)
      @ftp.login(@login, @password)
    end
    
    def disconnect
      return if not @ftp
      @ftp.close
      Dabcup::info("FTP disconnect from #{@login}@#{@host}")
    end
  end
  
  # SFTP
  class SFTP < Base
    def initialize(config)
      super(config)
      require('net/sftp')
    rescue LoadError => ex
      raise Dabcup::Error.new("The library net-ssh is missing. Get it via 'gem install net-ssh'")
    end
    
    def put(local_path, remote_name)
      connect
      remote_path = File.join(@path, remote_name)
      Dabcup::info("SFTP put #{local_path} to #{@login}@#{@host}:#{remote_path}")
      @sftp.put_file(local_path, remote_path)
    end
    
    def get(remote_name, local_path)
      connect
      remote_path = File.join(@path, remote_name)
      Dabcup::info("SFTP get #{local_path} from #{@login}@#{@host}:#{remote_path}")
      @sftp.get_file(remote_path, local_path)
    end
    
    def list
      connect
      dumps = []
      Dabcup::info("SFTP list #{@login}@#{@host}:#{@path}")
      handle = @sftp.opendir!(@path)
      while 1
        request = @sftp.readdir(handle).wait
        break if request.response.eof?
        raise "fail!" unless request.response.ok?
        request.response.data[:names].each do |file|
          next if file.name == '.' or file.name == '..'
          dumps << Dump.new(:name => file.name, :size => file.attributes.size)
        end
      end
      dumps
    end
    
    def delete(file_names)
      connect
      file_names = [file_names] if file_names.kind_of?(String)
      file_names.each do |file_name|
        file_path = File.join(@path, file_name)
        Dabcup::info("SFTP delete #{@login}@#{@host}:#{file_path}")
        @sftp.remove(file_path)
      end
    end
    
    def connect
      return if @sftp
      Dabcup::info("SFTP connect to #{@login}@#{@host}")
      @sftp = Net::SFTP.start(@host, @login, :password => @password)
      @sftp.connect
    end
    
    def disconnect
      return if not @sftp
      Dabcup::info("SFTP disconnect from #{@login}@#{@host}")
      @sftp.close(nil)
    end
  end
  
  class LOCAL < Base
    def initialize(config)
      super(config)
      @path = File.expand_path(@path)
    end
    
    def connect
      FileUtils.mkpath(@path) if not File.exist?(@path) 
      raise DabcupError.new("The path #{@path} is not a directory.") if not File.directory?(@path)
    end
    
    def disconnect
    end
    
    def put(local_path, remote_name)
      connect
      remote_path = File.join(@path, remote_name)
      Dabcup::info("LOCAL put #{local_path} to #{remote_path}")
      #File.include(FileUtils)
      FileUtils.copy(local_path, remote_path)
    end
    
    def get(remote_name, local_path)
      connect
      remote_path = File.join(@path, remote_name)
      Dabcup::info("LOCAL get #{local_path} from #{remote_path}")
      File.copy(remote_path, local_path)
    end
    
    def list
      connect
      dumps = []
      exclude = ['.', '..']
      Dabcup::info("LOCAL list #{@path}")
      Dir.foreach(@path) do |name|
        next if exclude.include?(name)
        path = File.join(@path, name)
        dumps << Dump.new(:name => name, :size => File.size(path))
      end
      dumps
    end
    
    def delete(file_name)
      connect
      file_path = File.join(@path, file_name)
      Dabcup::info("LOCAL delete #{file_path}")
      File.delete(file_path)
    end
  end
  
  class Dump
    attr_accessor :name
    attr_accessor :size
    attr_reader :dumped_at
    
    @@time_regex = /(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/
    
    def initialize(attrs = {})
      self.attributes = attrs
    end
    
    def created_at
      result = @@time_regex.match(name)
      Time.iso8601(result[0])
    end
    
    def attributes
      attrs = {}
      instance_variables.each do |name|
        attrs[name] = __send__(name)
      end
      attrs
    end
    
    def attributes=(attributes)
      attributes.each do |name, value|
        __send__(name.to_s + '=', value)
      end
    end
    
    def self.valid_name?(name)
      result = @@time_regex.match(name)
      result.size < 1
    end
  end
end
