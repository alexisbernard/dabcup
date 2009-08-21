module Dabcup
  module Operation
    class Delete < Base
      def run(args)
        raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help delete'") if args.size < 3
        @main_storage.delete(args[2])
        @spare_storage.delete(args[2]) if @spare_storage
      end
    end
  end
end