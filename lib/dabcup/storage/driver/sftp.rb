module Dabcup
  class Storage
    module Driver
      class SFTP < Base
        def initialize(uri)
          super(uri)
          require('net/sftp')
        rescue LoadError => ex
          raise Dabcup::Error.new("The library net-ssh is missing. Get it via 'gem install net-sftp' and set RUBYOPT=rubygems.")
        end

        def protocol
          'sftp'
        end

        def put(local_path, remote_name)
          remote_path = File.join(@uri.path, remote_name)
          sft.upload!(local_path, remote_path)
        end

        def get(remote_name, local_path)
          remote_path = File.join(@uri.path, remote_name)
          sftp.download!(remote_path, local_path)
        end

        def list
          dumps = []
          handle = sftp.opendir!(@uri.path)
          while 1
            request = sft.readdir(handle).wait
            break if request.response.eof?
            raise Dabcup::Error.new("Failed to list files from #{@login}@#{@host}:#{@uri.path}") unless request.response.ok?
            request.response.data[:names].each do |file|
              #next if exclude?(file.name)
              dumps << Dump.new(:name => file.name, :size => file.attributes.size)
            end
          end
          dumps
        end

        def delete(file_name)
          file_path = File.join(@uri.path, file_name)
          sft.remove!(file_path)
        end

        def disconnect
          @sftp.close(nil) if @sftp
        end

        def local?
          false
        end

        # Create directories if necessary
        def mkdirs
          dirs = []
          path = @uri.path
          first_exception = nil
          # TODO find an exists? method
          begin
            sftp.dir.entries(path)
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
          dirs.reverse.each { |dir| sftp.mkdir!(dir) }
        end

        def sftp
          unless @sftp
            @sftp = Net::SFTP.start(@uri.host, @uri.user, :password => @uri.password)
            @sftp.connect
            mkdirs
          end
          @sftp
        end
      end
    end
  end
end
