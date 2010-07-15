module Dabcup
  module Operation
    class Base
      attr_reader :profile

      def initialize(profile)
        @profile = profile
        @database = Dabcup::Database::Factory.new_database(@profile['database'])
        @main_storage = Dabcup::Storage::new(@profile['storage'])
        @spare_storage = Dabcup::Storage.new(@profile['spare_storage']) if @profile.has_key?('spare_storage')
      end

      def run
        raise NotImplementedError.new("Sorry")
      end

      def terminate
        @main_storage.disconnect if @main_storage
        @spare_storage.disconnect if @spare_storage
      end

      # Try to returns the best directory path to dump the database.
      def best_dumps_path
        if @database.via_ssh?
          return @main_storage.path if same_ssh_as_database?(@main_storage)
        else
          return @main_storage.path if @main_storage.local?
        end
        Dir.tmpdir
      end

      # Try to returns the best local directory path.
      def best_local_dumps_path
        return @spare_storage.path if @spare_storage.local?
        Dir.tmpdir
      end

      def remove_local_dump?
        not @main_storage.local? and not @spare_storage.local?
      end

      def same_ssh_as_database?(storage)
        return false if not storage.driver.is_a?(Dabcup::Storage::Driver::SFTP)
        storage.driver.host == @database.ssh_host and storage.driver.login == @database.ssh_login
      end

      def check
        return if not @database.via_ssh?
        if not same_ssh_as_database?(@main_storage)
          raise Error.new("When dumping via SSH the main storage must be local to the database.")
        end
      end
    end
  end
end
