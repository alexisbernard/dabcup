module Dabcup
  class Storage
    module Driver
      class SFTP < Base
        def initialize(config)
          super(config)
          require('net/sftp')
        rescue LoadError => ex
          raise Dabcup::Error.new("The library net-ssh is missing. Get it via 'gem install net-sftp' and set RUBYOPT=rubygems.")
        end

        def protocol
          'sftp'
        end

        def put(local_path, remote_name)
          remote_path = File.join(@path, remote_name)
          @sftp.upload!(local_path, remote_path)
        end

        def get(remote_name, local_path)
          remote_path = File.join(@path, remote_name)
          @sftp.download!(remote_path, local_path)
        end

        def list
          connect
          dumps = []
          handle = @sftp.opendir!(@path)
          while 1
            request = @sftp.readdir(handle).wait
            break if request.response.eof?
            raise Dabcup::Error.new("Failed to list files from #{@login}@#{@host}:#{@path}") unless request.response.ok?
            request.response.data[:names].each do |file|
              #next if exclude?(file.name)
              dumps << Dump.new(:name => file.name, :size => file.attributes.size)
            end
          end
          dumps
        end

        def delete(file_name)
          connect
          file_path = File.join(@path, file_name)
          @sftp.remove!(file_path)
        end

        def connect
          return if @sftp
          @sftp = Net::SFTP.start(@host, @login, :password => @password)
          @sftp.connect
          mkdirs
        end

        def disconnect
          return if not @sftp
          @sftp.close(nil)
        end

        def local?
          false
        end

        # Create directories if necessary
        def mkdirs
          dirs = []
          path = @path
          first_exception = nil
          # TODO find an exists? method
          begin
            @sftp.dir.entries(path)
          rescue Net::SFTP::StatusException => ex
            dirs << path
            path = File.dirname(path)
            first_exception ||= ex
            if path == '.'
              raise first_exception
            else
              retry
            end
          end
          dirs.reverse.each do |dir|
            @sftp.mkdir!(dir)
          end
        end
      end
    end
  end
end