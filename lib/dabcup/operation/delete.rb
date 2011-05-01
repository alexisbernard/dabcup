module Dabcup
  module Operation
    class Delete < Base
      def run(args)
        raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help delete'") if args.size < 3
        delete_from_storage(@main_storage, args[2])
        delete_from_storage(@spare_storage, args[2])
      end

      def delete_from_storage(storage, name)
        storage.delete(name) if storage.exists?(name)
      end
    end
  end
end
