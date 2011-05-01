module Dabcup
  module Operation
    class Store < Base
      def run(args)
        if @profile.via_ssh? && !same_ssh_as_database?(@main_storage)
          raise Dabcup::Error.new("Main storage must be on the same host than the database")
        end
        @profile.dump(dump_path)
        @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
        if @spare_storage
          @main_storage.get(dump_name, local_dump_path) if not File.exists?(local_dump_path)
          @spare_storage.put(local_dump_path, dump_name) if not @spare_storage.exists?(dump_name)
        end
      ensure
        path = local_dump_path || dump_path
        File.delete(path) if remove_local_dump? and File.exists?(path)
      end

      def dump_name
        @dump_name ||= @profile.name + '_' + Dabcup::time_to_name(Time.now)
      end

      def dump_path
        @dump_path ||= File.join(best_dumps_path, dump_name)
      end

      def local_dump_path
        File.exists?(dump_path) ? dump_path : File.join(best_local_dumps_path, dump_name)
      end
    end
  end
end
