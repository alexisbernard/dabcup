module Dabcup
  class Storage
    module Driver
      class FTP < Base
        def protocol
          'ftp'
        end

        def initialize(config)
          super(config)
          default_port(21)
        end

        def put(local_path, remote_name)
          remote_path = File.join(@path, remote_name)
          @ftp.putbinaryfile(local_path, remote_path)
        end

        def get(remote_name, local_path)
          remote_path = File.join(@path, remote_name)
          @ftp.getbinaryfile(remote_path, local_path)
        end

        def list
          dumps = []
          lines = @ftp.list(@path)
          lines.collect do |str|
            fields = str.split(' ')
            next if exclude?(fields[8])
            dumps << Dabcup::Storage::Dump.new(:name => fields[8], :size => fields[4].to_i)
          end
          dumps
        end

        def delete(file_name)
          file_path = File.join(@path, file_name)
          @ftp.delete(file_path)
        end

        def connect
          return if @ftp
          @ftp = Net::FTP.new
          @ftp.connect(@host, @port)
          @ftp.login(@login, @password)
          mkdirs
        end

        def disconnect
          return if not @ftp
          @ftp.close
        end

        def local?
          false
        end

        # TODO put it in Net::FTP
        def mkdirs
          dirs = []
          path = @path
          first_exception = nil
          begin
            @ftp.nlst(path)
          rescue Net::FTPTempError => ex
            dirs << path
            path = File.dirname(path)
            first_exception = ex unless first_exception
            if path == '.'
              raise first_exception
            else
              retry
            end
          end
          dirs.reverse.each do |dir|
            @ftp.mkdir(dir)
          end
        end
      end
    end
  end
end