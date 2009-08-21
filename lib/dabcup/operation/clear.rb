module Dabcup
  module Operation
    class Clear < Base
      def run(args)
        @main_storage.clear
        @spare_storage.clear if @spare_storage
      end
    end
  end
end