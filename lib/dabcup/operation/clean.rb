module Dabcup
  module Operation
    class Clean < Base
      def run(args)
        clean_storage(@main_storage) if @main_storage.rules
        clean_storage(@spare_storage) if @spare_storage and @spare_storage.rules
      end

      private

      def clean_storage(storage)
        black_list = []
        storage.list.each do |dump|
          if storage.rules.apply(dump) == Dabcup::Storage::Rules::REMOVE
            black_list << dump.name
          end
        end
        storage.delete(black_list)
      end
    end
  end
end