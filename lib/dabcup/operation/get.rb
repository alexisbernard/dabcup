module Dabcup
  module Operation
    class Get < Base
      def run(args)
        raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help get'.") if args.size < 3
        dump_name = args[2]
        local_path = args[3] || dump_name
        local_path = File.join(local_path, dump_name) if File.directory?(local_path)
        local_path = File.expand_path(local_path)
        # Try to get dump from main or spare storage
        if @main_storage.exists?(dump_name)
          @main_storage.get(dump_name, local_path)
        elsif @spare_storage.exists?(dump_name)
          @spare_storage.get(dump_name, local_path)
        else
          raise Dabcup::Error.new("Dump '#{dump_name}' not found.")
        end
      end
    end
  end
end