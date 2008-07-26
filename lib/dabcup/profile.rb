module Dabcup
  class Profile
    attr_reader :name
    attr_reader :config
    def initialize(name, config)
      @name = name
      @config = config
    end
  end
end