module Dabcup
  module Operation
    class Restore < Base
      def run(args)
        @database.via_ssh? ? restore_with_ssh(args) : restore_without_ssh(args)
      end

      def restore_without_ssh(args)
        raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help restore'") if args.size < 3
        dump_name = args[2]
        dump_path = File.join(Dir.tmpdir, dump_name)
        if @main_storage.exists?(dump_name)
          @main_storage.get(dump_name, dump_path)
        elsif @spare_storage and @spare_storage.exists?(dump_name)
          @spare_storage.get(dump_name, dump_path)
        else
          raise Dabcup::Error.new("Dump '#{dump_name}' not found.")
        end
        @database.restore(dump_path)
      end

      def retore_with_ssh(args)
        raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help restore'") if args.size < 3
        dump_name = args[2]
        dump_path = File.join(@main_storage.path, dump_name)
        local_dump_path = nil
        if not @main_storage.exists?(dump_name)
          if @spare_storage.is_a?(Dabcup::Storage::Local)
            local_dump_path = File.join(@spare_storage.path, dump_name)
          else
            @spare_storage.get(dump_name, local_dump_path)
          end
          @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
        end
        @database.restore(dump_path)
      ensure
        #File.delete(local_dump_path) if local_dump_path and File.exists?(local_dump_path)
      end
    end
  end
end
