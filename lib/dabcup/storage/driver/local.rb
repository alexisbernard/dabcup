module Dabcup
  class Storage
    module Driver
      class Local < Base
        def protocol
          'file'
        end

        def initialize(url)
          super(url)
          @path = File.expand_path(url.sub('file://', ''))
        end

        def put(local_path, remote_name)
          remote_path = File.join(@path, remote_name)
          FileUtils.copy(local_path, remote_path)
        end

        def get(remote_name, local_path)
          connect
          remote_path = File.join(@path, remote_name)
          FileUtils.copy(remote_path, local_path)
        end

        def list
          dumps = []
          Dir.foreach(@path) do |name|
            dumps << Dump.new(:name => name, :size => File.size(File.join(@path, name)))
          end
          dumps
        end

        def delete(file_name)
          file_path = File.join(@path, file_name)
          File.delete(file_path)
        end

        def connect
          FileUtils.mkpath(@path) if not File.exist?(@path)
          raise DabcupError.new("The path '#{@path}' is not a directory.") if not File.directory?(@path)
        end

        def disconnect
        end

        def local?
          true
        end
      end
    end
  end
end
