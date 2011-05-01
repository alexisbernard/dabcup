module Dabcup
  module Operation
    class Store < Base
      def run(args)
        @profile.via_ssh? ? dump_with_ssh(args) : dump_without_ssh(args)
      end

      def dump_without_ssh(args)
        local_dump_path = nil
        dump_name = @profile.name
        dump_name += Dabcup::time_to_name(Time.now)
        dump_path = File.join(best_dumps_path, dump_name)
        @profile.dump(dump_path)
        @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
        if @spare_storage
          local_dump_path = File.exists?(dump_path) ? dump_path : File.join(best_local_dumps_path, dump_name)
          @main_storage.get(dump_name, local_dump_path) if not File.exists?(local_dump_path)
          @spare_storage.put(local_dump_path, dump_name) if not @spare_storage.exists?(dump_name)
        end
      ensure
        local_dump_path ||= dump_path
        File.delete(local_dump_path) if remove_local_dump? and File.exists?(local_dump_path)
      end

      def dump_with_ssh(args)
        local_dump_path = nil
        dump_name = @profile.name + '_'
        dump_name += Dabcup::time_to_name(Time.now)
        dump_path = File.join(best_dumps_path, dump_name)
        raise Dabcup::Error.new("Main storage must be on the same host than the database") if not same_ssh_as_database?(@main_storage)
        @profile.dump(dump_path)
        @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
        if @spare_storage
          local_dump_path = File.exists?(dump_path) ? dump_path : File.join(best_local_dumps_path, dump_name)
          @main_storage.get(dump_name, local_dump_path) if not File.exists?(local_dump_path)
          @spare_storage.put(local_dump_path, dump_name) if not @spare_storage.exists?(dump_name)
        end
      ensure
        local_dump_path ||= dump_path
        File.delete(local_dump_path) if remove_local_dump? and File.exists?(local_dump_path)
      end
    end
  end
end
