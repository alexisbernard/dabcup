module Dabcup
  class Storage
    module Driver
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
          begin
            @rules = Rules.new(config['rules']) if config['rules']
          rescue ArgumentError => ex
            raise Dabcup::Error.new("Invalid rules for storage #{name}.")
          end
        end

        #### Methods to implement ###

        # Connects to remote host.
        def connect
          raise NotImplementedError
        end

        # Disconnects from remote host.
        def disconnect
          raise NotImplementedError
        end

        def put(local_path, remote_name)
          raise NotImplementedError
        end

        def get(remote_name, local_path)
          raise NotImplementedError
        end

        def list
          raise NotImplementedError
        end

        def delete(dump_name)
          raise NotImplementedError
        end

        def protocol
          raise NotImplementedError
        end

        def local?
          raise NotImplementedError
        end

        ### End methods to implement ###
      end
    end
  end
end