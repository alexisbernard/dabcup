module Dabcup
  class Storage
    module Driver
      class Factory
        @@storages_config = {}

        def self.storages_config=(storages_config)
          storages_config = {} if not storages_config
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
            Dabcup::Storage::Driver::S3.new(storage_config)
          when 'FTP':
            Dabcup::Storage::Driver::FTP.new(storage_config)
          when 'SFTP':
            Dabcup::Storage::Driver::SFTP.new(storage_config)
          when 'LOCAL'
            Dabcup::Storage::Driver::Local.new(storage_config)
          #when 'REMOTE'
          #  Dabcup::Storage::Remote.new(storage_config)
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
    end
  end
end