module Dabcup::Operation
  class Base
    def initialize(config)
      @config = config
      @db = Dabcup::Database::Factory.new_database(@config['database'])
      @main_storage = Dabcup::Storage::Factory.new_storage(@config['storage'])
      @spare_storage = Dabcup::Storage::Factory.new_storage(@config['spare_storage']) if @config.has_key?('spare_storage')
    end
    
    def run
      raise NotImplementedError.new("Sorry")
    end
    
    def terminate
      @main_storage.disconnect if @main_storage
      @spare_storage.disconnect if @spare_storage
    end
  end
  
  class Store < Base
    def run(args)
      file_name = @config['database']['name'] + '_'
      file_name += Dabcup::time_to_name(Time.now)
      file_path = File.join(Dir.tmpdir, file_name)
      @db.dump(file_path)
      @main_storage.put(file_path, file_name)
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
      if @main_storage.exists?(file_name)
        @main_storage.get(file_name, file_path)
      elsif @spare_storage and @spare_storage.exists?(file_name)
        Dabcup::info("Get '#{args[2]}.dump' from the spare storage")
        @spare_storage.get(file_name, file_path)
      else
        raise Dabcup::Error.new("Dump '#{file_name}' not found.")
      end
      @db.restore(file_path)
    end
  end
  
  # List all dumps available
  class List < Base
    def run(args)
      max_length = 0
      main_dumps = @main_storage.list
      spare_dumps = @spare_storage ? @spare_storage.list : []
      # Intersection of main_dumps and spare_dumps
      dumps = main_dumps + spare_dumps.select do |dump| not main_dumps.include?(dump) end
      # Sort dumps by date
      dumps.sort! do |left, right| left.created_at <=> right.created_at end
      # Get length of the longest name
      max_length = dumps.max do |left, right| left.name.size <=> right.name.size end.name.size
      # Prints names, sizes and flags
      dumps.each do |dump|
        name_str = dump.name.ljust(max_length + 2)
        size_str = (dump.size / 1024).to_s.rjust(8)
        location = main_dumps.include?(dump) ? 'M' : ' '  
        location += spare_dumps.include?(dump) ? 'S' : ' '
        puts "#{name_str}#{size_str} KB #{location}"
      end
    end
  end
  
  class Get < Base
    def run(args)
      raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help get'.") if args.size < 3
      dump_name = args[2]
      local_path = args[3] || dump_name
      local_path = File.join(local_path, dump_name) if File.directory?(local_path)
      local_path = File.expand_path(local_path)
      # Try to get dump from main or spare storage
      if @main_storage.exists?(dump_name)
        @main_storage.get(dump_name, local_path)
      elsif @spare_storage.exists?(dump_name)
        @spare_storage.get(dump_name, local_path)
      else
        raise Dabcup::Error.new("Dump '#{dump_name}' not found.")
      end
    end
  end
  
  # Clean the storage and spare_storage
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
  
  # Delete a specified dump
  class Delete < Base
    def run(args)
      raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help delete'") if args.size < 3
      @main_storage.delete(args[2])
      @spare_storage.delete(args[2]) if @spare_storage
    end
  end
  
  class Populate < Base
    def run(args)
      now = Time.now
      days_before = args[2].to_i
      local_file_name = Dabcup::Database::dump_name(@db)
      local_file_path = File.join(Dir.tmpdir, local_file_name)
      @db.dump(local_file_path)
      for day_before in (0 .. days_before)
        remote_file_name = Dabcup::Database::dump_name(@db, now - (day_before * 24 * 3600))
        @main_storage.put(local_file_path, remote_file_name)
        @spare_storage.put(local_file_path, remote_file_name) if @spare_storage
      end
      ensure
        File.delete(local_file_path) if local_file_path and File.exists?(local_file_path)
    end
  end
  
  class Clear < Base
    def run(args)
      @main_storage.clear
      @spare_storage.clear if @spare_storage
    end
  end
  
  class Test < Base
    def run(args)
      test_name = args[2].capitalize
      attributes = {
        :database => @db,
        :main_storage => @main_storage,
        :spare_storage => @spare_storage }
      test = Dabcup::Test::Factory.new_test(test_name, attributes)
      test.run
      failes = 0
      test.cases.each do |test_case|
        puts "#{test_case.name}: #{test_case.result}"
        next if test_case.result
        puts "  #{test_case.exception.inspect}"
        puts "  #{test_case.exception.backtrace.join("\n    ")}"
        failes += 1
      end
      puts ""
      puts "Cases: #{test.cases.size}, Success: #{test.cases.size - failes}, Failes: #{failes}"
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
      when 'get'
        operation = Dabcup::Operation::Get.new(config)
      when 'delete'
        operation = Dabcup::Operation::Delete.new(config)
      when 'clear'
        operation = Dabcup::Operation::Clear.new(config)
      when 'clean'
        operation = Dabcup::Operation::Clean.new(config)
      when 'populate'
        operation = Dabcup::Operation::Populate.new(config)
      when 'test'
        operation = Dabcup::Operation::Test.new(config)
      else
        raise Dabcup::Error.new("Unknow operation '#{name}'.")
      end
      operation
    end
  end
end
