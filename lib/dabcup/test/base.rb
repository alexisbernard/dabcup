module Dabcup::Test
  class Base
    include Dabcup::MassAssignment
    
    attr_reader :cases
    attr_accessor :database
    attr_accessor :main_storage
    attr_accessor :spare_storage

    def initialize(attributes)
      @cases = []
      define_cases
      self.attributes = attributes
    end

    def define_cases
      raise NotImplementedError.new('Sorry.')
    end

    def add_case(attributes)
      @cases << Dabcup::Test::Case.new(attributes)
    end

    def run
      for test_case in @cases
        begin
          send(test_case.name)
          test_case.result = true
          test_case.exception = nil
        rescue => ex
          test_case.result = false
          test_case.exception = ex
        end
      end
    end
  end

  class Factory
    def self.new_test(class_name, attributes)
      # TODO Check class_name if in [ ... ]
      Dabcup::Test::const_get(class_name).new(attributes)
    end
  end
  
  class Case
    include Dabcup::MassAssignment

    attr_accessor :name
    attr_accessor :description
    attr_accessor :exception
    attr_accessor :result

    def initialize(attrs)
      self.attributes = attrs
    end
  end


  #class Dabcup::Test::Suite
  #  
  #end
end