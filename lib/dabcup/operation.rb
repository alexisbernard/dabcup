module Dabcup::Operation
  class Base
    def initialize(config)
      @config = config
      @db = Dabcup::Database::Factory.new_database(@config['database'])
      @storage = Dabcup::Storage::Factory.new_storage(@config['storage'])
      @spare_storage = Dabcup::Storage::Factory.new_storage(@config['spare_storage']) if @config.has_key?('spare_storage')
    end
    
    def terminate
      @storage.disconnect
      @spare_storage.disconnect if @spare_storage
    end
  end
  
  class Store < Base
    def run(args)
      file_name = Time.new.strftime('%Y.%m.%d') + '.dump'
      file_path = File.join(Dir.tmpdir, file_name)
      @db.dump(file_path)
      @storage.put(file_path, file_name)
      @spare_storage.put(file_path, file_name) if @spare_storage
      ensure
        File.delete(file_path) if File.exists?(file_path)
    end
  end
  
  # Restore a dump file stored on a remote place
  class Restore < Base
    def run(args)
      file_name = args[2] + '.dump'
      file_path = File.join(Dir.tmpdir, file_name)
      if @storage.exists?(file_name)
        @storage.get(file_name, file_path)
      else
        if not @spare_storage.nil? and @spare_storage.exists?(file_name)
          Dabcup::info("Get '#{args[2]}.dump' from the spare storage")
          @spare_storage.get(file_name, file_path)
        else
          raise "No '#{args[2]}' dump found"
        end
      end
      @db.restore(file_path)
    end
  end
  
  # List all dumps available
  class List < Base
    def run(args)
      @storage.list.each do |name|
        puts name
      end
    end
  end
  
  # Clean the storage and spare_storage
  class Clean < Base
    def run(args)
      cleaned = false
      if @config['storage'].has_key?('keep')
        clean_storage(@storage, @config['storage']['keep'])
        cleaned = true
      end
      if not @spare_storage.nil? and @config['spare_storage'].has_key?('keep')
        clean_storage(@spare_storage, @config['spare_storage']['keep'])
        cleaned = true
      end
      raise "Expected a 'keep' section either for 'storage' or 'spare_storage'" if not cleaned
    end
    
    private
    
    def clean_storage(storage, keep)
      now = Time.new
      dow = keep.has_key?('days_of_week') ? extract_numbers(keep['days_of_week'].to_s) : []
      dom = keep.has_key?('days_of_month') ? extract_numbers(keep['days_of_month'].to_s) : []
      ldt = keep.has_key?('less_days_than') ? keep['less_days_than'].to_i : 0
      raise "Expected a 'days_of_week' or 'days_of_month' or 'less_days_than' section" if dow.nil? and dom.nil? and ldt.nil?
      black_list = []
      regex = /(\d\d\d\d)\.(\d\d).(\d\d)\./
      storage.list.each do |file_name|
        result = regex.match(file_name)
        dumped_on = Time.local(result[1], result[2], result[3])
        next if (now - dumped_on) / (3600 * 24) < ldt
        next if dow.include?(dumped_on.wday)
        next if dom.include?(dumped_on.mday)
        black_list << file_name
      end
      storage.delete(black_list)
    end
    
    def extract_numbers(str)
      nums = []
      str.each(',') do |num| nums << num.strip.to_i end
      nums
    end
  end
  
  # Delete a specified dump
  class Delete < Base
    def run(args)
      @storage.delete(args[2] + '.dump')
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
        raise "Unknow operation #{name}"
      end
      operation
    end
  end
end