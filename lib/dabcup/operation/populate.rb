module Dabcup
  module Operation
    class Populate < Base
      def run(args)
        now = Time.now
        days_before = args[2].to_i
        local_file_name = Dabcup::Database::dump_name(@database)
        local_file_path = File.join(Dir.tmpdir, local_file_name)
        @database.dump(local_file_path)
        for day_before in (0 .. days_before)
          remote_file_name = Dabcup::Database::dump_name(@database, now - (day_before * 24 * 3600))
          @main_storage.put(local_file_path, remote_file_name)
          @spare_storage.put(local_file_path, remote_file_name) if @spare_storage
        end
        ensure
          File.delete(local_file_path) if local_file_path and File.exists?(local_file_path)
      end
    end
  end
end