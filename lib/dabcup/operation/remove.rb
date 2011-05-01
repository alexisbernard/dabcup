module Dabcup
  module Operation
    class Remove < Base
      def run(args)
        raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help delete'") if args.size < 3
        remove_from_storage(main_storage, args[2])
        remove_from_storage(spare_storage, args[2])
      end

      def remove_from_storage(storage, name)
        storage.delete(name) if storage.exists?(name)
      end
    end
  end
end
