require 'logger'

module Dabcup
  class App
    DABCUP_PATH = File.expand_path('~/.dabcup')
    LOG_PATH = File.expand_path(File.join(DABCUP_PATH, 'dabcup.log'))
    PROFILES_PATH = File.expand_path(File.join(DABCUP_PATH, 'profiles.yml'))
    CONFIGURATION_PATH = File.expand_path(File.join(DABCUP_PATH, 'configuration.yml'))
    
    def initialize(app_dir)
      @app_dir = app_dir
      initialize_config
      @config = load_yaml(CONFIGURATION_PATH)
      @profiles = load_yaml(PROFILES_PATH)
      initialize_logger
      initialize_storages
    end
    
    # Create configuration directory and files if they are missing.
    def initialize_config
      Dir.mkdir(DABCUP_PATH) if not File.directory?(DABCUP_PATH)
      FileUtils.cp(File.join(@app_dir, 'profiles.yml'), PROFILES_PATH) if not File.exists?(PROFILES_PATH)
      FileUtils.cp(File.join(@app_dir, 'configuration.yml'), CONFIGURATION_PATH) if not File.exists?(CONFIGURATION_PATH)
    end
    
    def initialize_logger
      @config = @config.has_key?('config') ? @config['config'] : nil
      log_path = @config['log_path'] || LOG_PATH
      log_path = File.expand_path(log_path)
      log_level = @config['log_level']
      log_age = @config['log_age'].to_i
      log_size = @config['log_size'].to_i * 1024 * 1024
      log_size = 5 * 1024 * 1024 if log_size < 1
      log_datetime_format = @config['log_datetime_format']
      
      case log_level
      when 'debug':
        log_level = Logger::DEBUG
      when 'info':
        log_level = Logger::INFO
      when 'warn':
        log_level = Logger::WARN
      when 'error':
        log_level = Logger::ERROR
      when 'fatal':
        log_level = Logger::FATAL
      else
        $stderr.puts("Invalid log level '#{log_level}, use error level instead.")
        log_level = Logger::ERROR
      end
      
      logger = Logger.new(log_path, log_age, log_size)
      logger.level = log_level if log_level
      logger.datetime_format = log_datetime_format if log_datetime_format
      Dabcup::set_logger(logger)
    end
    
    def initialize_storages
      Dabcup::Storage::Factory::storages_config = @storages = @profiles['storages']
    end
    
    def main(args)
      if args.size < 1
        puts "Try 'dabcup help'."
      elsif ['help', '-h', '--help', '?'].include?(args[0])
        help(args)
      else
        run(args)
      end
    rescue Dabcup::Error => ex
      $stderr.puts ex.message
    rescue => ex
      $stderr.puts ex.message
      $stderr.puts 'See log for more informations.'
      Dabcup::fatal(ex)
    end
    
    def run(args)
      profile_name, operation_name = args[0 .. 1]
      raise Dabcup::Error.new("Profile '#{profile_name}' doesn't exist.") if not @profiles[profile_name]
      operation = Operation::Factory.new_operation(operation_name, @profiles[profile_name])
      Dabcup::info("Begin #{operation_name} #{profile_name}")
      operation.run(args)
      Dabcup::info("End #{operation_name} #{profile_name}")
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
  end
end