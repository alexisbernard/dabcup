require 'net/ftp'

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
  end

  class Factory
    def self.new_storage(storage_config)
      adapter = storage_config['adapter']
      case adapter
      when 'S3':
        @storage = Dabcup::Storage::S3.new(storage_config)
      when 'FTP':
        @storage = Dabcup::Storage::FTP.new(storage_config)
      when 'SFTP':
        @storage = Dabcup::Storage::SFTP.new(storage_config)
      else
        raise "Unknow #{adapter} storage adapter"
      end
    end
  end
  
  # Amazon S3
  class S3 < Base
    def initialize(config)
      super(config)
      require 'aws/s3'
      @bucket = config['bucket']
    rescue LoadError => ex
      Dabcup::error("The library aws-s3 is missing. Get it via 'gem install aws-s3'")
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
      AWS::S3::Bucket.find(@bucket).objects.collect do |obj| obj.key end
    end
    
    def delete(file_names)
      connect
      file_names = [file_names] if file_names.kind_of?(String)
      file_names.each do |file_name|
        Dabcup::info("S3 delete #{@bucket}:#{file_name}")
        AWS::S3::S3Object.delete(file_name, @bucket)
      end
    end
    
    def exists?(file_name)
      connect
      AWS::S3::S3Object.exists?(file_name, @bucket)
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
      result = nil
      Dabcup::info("FTP list #{@login}@#{@host}:#{@path}")
      result = @ftp.list(@path)
      regex = /\s\d\d:\d\d\s(.*)$/
      result = result.collect do |str| regex.match(str)[1] end
      result.delete('.')
      result.delete('..')
      result
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
    
    def exists?(file_name)
      list.include?(file_name)
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
      Dabcup::error("The library net-ssh is missing. Get it via 'gem install net-ssh'")
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
      result = nil
      Dabcup::info("SFTP list #{@login}@#{@host}:#{@path}")
      handle = @sftp.opendir(@path)
      items = @sftp.readdir(handle)
      result = items.collect do |item| item.filename end
      @sftp.close_handle(handle)
      result.delete('.')
      result.delete('..')
      result
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
    
    def exists?(file_name)
      list.include?(file_name)
    end
    
    def connect
      return if @sftp
      Dabcup::info("SFTP connect to #{@login}@#{@host}")
      @sftp = Net::SFTP.start(@host, @login, @password)
      @sftp.connect
    end
    
    def disconnect
      return if not @sftp
      Dabcup::info("SFTP disconnect from #{@login}@#{@host}")
      @sftp.close 
    end
  end
end
