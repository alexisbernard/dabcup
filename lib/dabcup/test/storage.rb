module Dabcup::Test
  class Storage < Base
    def initialize(attributes)
      super(attributes)
      @dump_name = Dabcup::Database.dump_name(@database)
      @database.dump(@dump_name)
    end

    def define_cases
      add_case(:name => 'put_main_storage', :description => '')
      add_case(:name => 'get_main_storage', :description => '')
      add_case(:name => 'list_main_storage', :description => '')
      add_case(:name => 'delete_by_name_main_storage', :description => '')
      add_case(:name => 'delete_main_storage', :description => '')
      add_case(:name => 'clear_main_storage', :description => '')
      
      add_case(:name => 'put_spare_storage', :description => '')
      add_case(:name => 'get_spare_storage', :description => '')
      add_case(:name => 'list_spare_storage', :description => '')
      add_case(:name => 'delete_by_name_spare_storage', :description => '')
      add_case(:name => 'delete_spare_storage', :description => '')
      add_case(:name => 'clear_spare_storage', :description => '')
    end

    # Tests on main storage
    
    def put_main_storage
      put(@main_storage)
    end
    
    def get_main_storage
      get(@main_storage)
    end
    
    def list_main_storage
      list(@main_storage)
    end
    
    def delete_by_name_main_storage
      delete_by_name(@main_storage)
    end
    
    def delete_main_storage
      delete(@main_storage)
    end
    
    def clear_main_storage
      clear(@main_storage)
    end
    
    # Tests on spare storage
    
    def put_spare_storage
      raise "No spare storage defined" if not @spare_storage
      put(@spare_storage)
    end
    
    def get_spare_storage
      raise "No spare storage defined" if not @spare_storage
      get(@spare_storage)
    end
    
    def list_spare_storage
      raise "No spare storage defined" if not @spare_storage
      list(@spare_storage)
    end
    
    def delete_by_name_spare_storage
      raise "No spare storage defined" if not @spare_storage
      delete_by_name(@spare_storage)
    end
    
    def delete_spare_storage
      raise "No spare storage defined" if not @spare_storage
      delete(@spare_storage)
    end
    
    def clear_spare_storage
      raise "No spare storage defined" if not @spare_storage
      clear(@spare_storage)
    end
    
    # Test code
    
    def put(storage)
      storage.put(@dump_name, @dump_name)
      raise "Dump '#{@dump_name}' does not exists." if not storage.exists?(@dump_name)
    end

    def get(storage)
      local_dump_name = 'get-' + @dump_name
      storage.get(@dump_name, local_dump_name)
      raise "Dump '#{@dump_name}' has not been retrieve." if not File.exists?(local_dump_name)
      raise "Dump '#{@dump_name}' is empty." if File.size(local_dump_name) < 1
    end

    def list(storage)

    end

    def delete_by_name(storage)
      dump_name = storage.list.first.name
      storage.delete_by_name(dump_name)
      raise "Dump '#{dump_name}' has been deleted." if storage.exists?(dump_name)
    end

    def delete(storage)
      populate(storage, 3)
      dumps = storage.list[0..1]
      storage.delete(dumps)
      for dump in dumps
        raise "Dump '#{dump.name}' has not been deleted." if storage.exists?(dump)
      end
    end

    def clear(storage)
      populate(storage, 2) if storage.list.size < 2
      raise "Not populated" if storage.list.size < 2
      storage.clear
      raise "Not cleared" if storage.list.size > 0
    end
    
    # Utils method
    def populate(storage, days_before)
      local_file_path = @dump_name
      for day_before in (0 .. days_before)
        remote_file_name = Dabcup::Database::dump_name(@database, Time.now - (day_before * 24 * 3600))
        storage.put(local_file_path, remote_file_name)
      end
    end
  end
end