module Dabcup
  class App
    DABCUP_PATH = File.expand_path('~/.dabcup')
    CONFIG_PATHS = ['dabcup.yml', '~/.dabcup/profiles.yml', '/etc/dabcup/profiles.yml'].freeze

    attr_reader :config
    attr_reader :profiles


    def initialize(app_dir)
      @app_dir = app_dir
    end
    
    def main(args)
      if args.size < 1
        puts "Try 'dabcup help'."
      elsif ['help', '-h', '--help', '?'].include?(args[0])
        help(args)
      else
        run(args)
      end
    #rescue Dabcup::Error => ex
    #  $stderr.puts ex.message
    #rescue => ex
    #  $stderr.puts ex.message
    #  $stderr.puts 'See log for more informations.'
    #  Dabcup::fatal(ex)
    end
    
    def run(args)
      database_name, operation_name = args[0 .. 1]
      raise Dabcup::Error.new("Database '#{database_name}' doesn't exist.") unless config[database_name]
      database = Database.new(database_name, config[database_name])
      operation = Operation.build(operation_name, database)
      operation.run(args)
    ensure
      operation.terminate if operation
    end
    
    def help(args)
      puts Dabcup::Help.message(args[1])
    end
    
    private
    
    def load_yaml(file_path)
      File.open(File.expand_path(file_path)) do |stream| YAML.load(stream) end
    end
    
    def config_path
      CONFIG_PATHS.find { |path| File.exists?(path) }
    end
    
    def config
      @config ||= YAML.load_file(config_path)
    end
  end
end
