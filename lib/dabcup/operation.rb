module Dabcup::Operation
  class Base
    attr_reader :profile
    
    def initialize(profile)
      @profile = profile
      @database = Dabcup::Database::Factory.new_database(@profile['database'])
      #@main_storage = Dabcup::Storage::Factory.new_storage(@profile['storage'])
      #@spare_storage = Dabcup::Storage::Factory.new_storage(@profile['spare_storage']) if @profile.has_key?('spare_storage')

      @main_storage = Dabcup::Storage::new(@profile['storage'])
      @spare_storage = Dabcup::Storage.new(@profile['spare_storage']) if @profile.has_key?('spare_storage')

      #@main_storage = Dabcup::Storage::Driver::Factory.new_storage(@profile['storage'])
      #@spare_storage = Dabcup::Storage::Driver::Factory.new_storage(@profile['spare_storage']) if @profile.has_key?('spare_storage')
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
      return false if not storage.is_a?(Dabcup::Storage::SFTP)
      storage.host == @database.ssh_host and storage.login == @database.ssh_login
    end
    
    def check
      return if not @database.via_ssh?
      if not same_ssh_as_database?(@main_storage)
        raise Error.new("When dumping via SSH the main storage must be local to the database.")
      end
    end
  end
  
  class Store < Base
    def run(args)
      @database.via_ssh? ? dump_with_ssh(args) : dump_without_ssh(args)
    end
    
    def dump_without_ssh(args)
      local_dump_path = nil
      dump_name = @profile['database']['name'] + '_' # TODO replace by profile name
      dump_name += Dabcup::time_to_name(Time.now)
      dump_path = File.join(best_dumps_path, dump_name)
      @database.dump(dump_path)
      @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
      if @spare_storage
        local_dump_path = File.exists?(dump_path) ? dump_path : File.join(best_local_dumps_path, dump_name)
        @main_storage.get(dump_name, local_dump_path) if not File.exists?(local_dump_path)
        @spare_storage.put(local_dump_path, dump_name) if not @spare_storage.exists?(dump_name)
      end
    ensure
      local_dump_path ||= dump_path
      File.delete(local_dump_path) if remove_local_dump? and File.exists?(local_dump_path)
    end
    
    def dump_with_ssh(args)
      local_dump_path = nil
      dump_name = @profile['database']['name'] + '_' # TODO replace by profile name
      dump_name += Dabcup::time_to_name(Time.now)
      dump_path = File.join(best_dumps_path, dump_name)
      raise Dabcup::Error.new("Main storage must be on the same host than the database") if not same_ssh_as_database?(@main_storage)
      @database.dump(dump_path)
      @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
      if @spare_storage
        local_dump_path = File.exists?(dump_path) ? dump_path : File.join(best_local_dumps_path, dump_name)
        @main_storage.get(dump_name, local_dump_path) if not File.exists?(local_dump_path)
        @spare_storage.put(local_dump_path, dump_name) if not @spare_storage.exists?(dump_name)
      end
    ensure
      local_dump_path ||= dump_path
      File.delete(local_dump_path) if remove_local_dump? and File.exists?(local_dump_path)
    end
  end
  
  # Restore a dump file stored on a remote place
  class Restore < Base
    def run(args)
      @database.via_ssh? ? restore_with_ssh(args) : restore_without_ssh(args)
    end
    
    def restore_without_ssh(args)
      raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help restore'") if args.size < 3
      dump_name = args[2]
      dump_path = File.join(Dir.tmpdir, dump_name)
      if @main_storage.exists?(dump_name)
        @main_storage.get(dump_name, dump_path)
      elsif @spare_storage and @spare_storage.exists?(dump_name)
        Dabcup::info("Get '#{args[2]}.dump' from the spare storage")
        @spare_storage.get(dump_name, dump_path)
      else
        raise Dabcup::Error.new("Dump '#{dump_name}' not found.")
      end
      @database.restore(dump_path)
    end
    
    def retore_with_ssh(args)
      raise Dabcup::Error.new("Not enough arguments. Try 'dabcup help restore'") if args.size < 3
      dump_name = args[2]
      dump_path = File.join(@main_storage.path, dump_name)
      local_dump_path = nil
      if not @main_storage.exists?(dump_name)
        if @spare_storage.is_a?(Dabcup::Storage::Local)
          local_dump_path = File.join(@spare_storage.path, dump_name)
        else
          @spare_storage.get(dump_name, local_dump_path)
        end
        @main_storage.put(dump_path, dump_name) if not @main_storage.exists?(dump_name)
      end
      @database.restore(dump_path)
    ensure
      #File.delete(local_dump_path) if local_dump_path and File.exists?(local_dump_path)
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
        :database => @database,
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
