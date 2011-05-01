module Dabcup
  module Operation
    class Store < Base
      def run(args)
        database.dump(dump_path)
        copy_dump_to_main_storage
        copy_dump_to_spare_storage
      ensure
        path = local_dump_path || dump_path
        File.delete(path) if remove_local_dump? && File.exists?(path)
      end

      private

      def copy_dump_to_main_storage
        unless main_storage.exists?(dump_name)
          retrieve_dump_from_remote_database if retrieve_dump_from_remote_database?
          main_storage.put(dump_path, dump_name)
        end
      end

      def copy_dump_to_spare_storage
        if spare_storage && !spare_storage.exists?(dump_name)
          main_storage.get(dump_name, local_dump_path) unless File.exists?(local_dump_path)
          spare_storage.put(local_dump_path, dump_name) unless spare_storage.exists?(dump_name)
        end
      end

      def dump_name
        @dump_name ||= database.name + '_' + Dabcup::time_to_name(Time.now)
      end

      def dump_path
        @dump_path ||= File.join(best_dumps_path, dump_name)
      end

      def local_dump_path
        File.exists?(dump_path) ? dump_path : File.join(best_local_dumps_path, dump_name)
      end

      def retrieve_dump_from_remote_database
        Storage::Driver.build(database.tunnel.to_s + '/tmp').get(dump_name, local_dump_path)
      end

      def retrieve_dump_from_remote_database?
        database.via_ssh? && !same_ssh_as_database?(main_storage)
      end
    end
  end
end
