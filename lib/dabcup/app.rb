require 'logger'

module Dabcup
  class App
    DABCUP_PATH = File.expand_path('~/.dabcup')
    LOG_PATH = File.expand_path(File.join(DABCUP_PATH, 'dabcup.log'))
    PROFILES_PATH = File.expand_path(File.join(DABCUP_PATH, 'profiles.yml'))
    PROFILES_PATHS = ['dabcup.yml', '~/.dabcup/profiles.yml', '/etc/dabcup/profiles.yml'].freeze

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
      profile_name, operation_name = args[0 .. 1]
      raise Dabcup::Error.new("Profile '#{profile_name}' doesn't exist.") if not profiles[profile_name]
      profile = Database.new(profile_name, profiles[profile_name])
      operation = Operation.build(operation_name, profile)
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
    
    def profiles_path
      PROFILES_PATHS.find { |path| File.exists?(path) }
    end
    
    def profiles
      @profiles ||= YAML.load_file(profiles_path)
    end
  end
end
