module Dabcup::Operation
  class Base
    def initialize(config)
      @config = config
      @db = Dabcup::Database::Factory.new_database(@config['database'])
      @storage = Dabcup::Storage::Factory.new_storage(@config['storage'])
      @spare_storage = Dabcup::Storage::Factory.new_storage(@config['spare_storage']) if @config.has_key?('spare_storage')
    end
    
    def run
      raise NotImplementedError.new("Sorry")
    end
    
    def terminate
      @storage.disconnect if @storage
      @spare_storage.disconnect if @spare_storage
    end
  end
  
  class Store < Base
    def run(args)
      file_name = @config['database']['name'] + '_'
      file_name += Dabcup::time_to_name(Time.now)
      file_path = File.join(Dir.tmpdir, file_name)
      @db.dump(file_path)
      @storage.put(file_path, file_name)
      @spare_storage.put(file_path, file_name) if @spare_storage
      ensure
        File.delete(file_path) if file_path and File.exists?(file_path)
    end
  end
  
  # Restore a dump file stored on a remote place
  class Restore < Base
    def run(args)
      raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help restore'") if args.size < 3
      file_name = args[2]
      file_path = File.join(Dir.tmpdir, file_name)
      if @storage.exists?(file_name)
        @storage.get(file_name, file_path)
      else
        if @spare_storage and @spare_storage.exists?(file_name)
          Dabcup::info("Get '#{args[2]}.dump' from the spare storage")
          @spare_storage.get(file_name, file_path)
        else
          raise Dabcup::Error.new("Dump '#{file_name}' not found.")
        end
      end
      @db.restore(file_path)
    end
  end
  
  # List all dumps available
  class List < Base
    def run(args)
      max_length = 0
      dumps = @storage.list
      dumps.sort! do |left, right| left.created_at <=> right.created_at end
      # Get length of longest name
      dumps.each do |dump|
        max_length = dump.name.size if dump.name.size  > max_length
      end
      # Prints names and sizes
      dumps.each do |dump|
        name_str = dump.name.ljust(max_length + 2)
        size_str = (dump.size / 1024).to_s.rjust(8)
        puts "#{name_str}#{size_str} KB"
      end
    end
  end
  
  # Clean the storage and spare_storage
  class Clean < Base
    def run(args)
      cleaned = false
      if @storage.rules
        clean_storage(@storage)
        cleaned = true
      end
      if @spare_storage and @spare_storage.rules
        clean_storage(@spare_storage)
        cleaned = true
      end
      raise Dabcup::Error.new("Operation clean expects a 'rules' section either for 'storage' or 'spare_storage'.") if not cleaned
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
  
  # Delete a specified dump
  class Delete < Base
    def run(args)
      raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help delete'") if args.size < 3
      @storage.delete(args[2])
      @spare_storage.delete(args[2]) if @spare_storage
    end
  end
  
  class Factory
    def self.new_operation(name, config)
      case name
      when 'store'
        operation = Dabcup::Operation::Store.new(config)
      when 'restore'
        operation = Dabcup::Operation::Restore.new(config)
      when 'list'
        operation = Dabcup::Operation::List.new(config)
      when 'clean'
        operation = Dabcup::Operation::Clean.new(config)
      when 'delete'
        operation = Dabcup::Operation::Delete.new(config)
      else
        raise Dabcup::Error.new("Unknow operation '#{name}'.")
      end
      operation
    end
  end
end
