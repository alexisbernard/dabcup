module Dabcup
  class Profile
    attr_reader :name
    attr_reader :config
    attr_reader :database
    attr_reader :main_storage
    attr_reader :spare_storage
    
    def initialize(name, config)
      @name = name
      @config = config
      @database = Dabcup::Database::Factory.new_database(@config['database'])
      @main_storage = Dabcup::Storage::Factory.new_storage(@config['storage'])
      @spare_storage = Dabcup::Storage::Factory.new_storage(@config['spare_storage']) if @config.has_key?('spare_storage')
    end
  end
end