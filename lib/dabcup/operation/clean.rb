module Dabcup
  module Operation
    class Clean < Base
      def run(args)
        clean_storage(@main_storage)
        clean_storage(@spare_storage) if @spare_storage
      end

      private

      def clean_storage(storage)
        if (retention = @database.retention.to_i) < 1
          raise Error.new("Retention must be greater than zero")
        end
        storage.delete(storage.list[0 .. -retention-1])
      end
    end
  end
end
