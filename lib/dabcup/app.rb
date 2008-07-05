require 'logger'

module Dabcup
  class App
    def initialize(app_dir)
      @app_dir = app_dir
      profiles_path = File.expand_path('~/.dabcup/profiles.yml')
      @profiles = File.open(profiles_path) do |stream| YAML.load(stream) end
      initialize_logger
      initialize_storages
    end
    
    def initialize_logger
      @config = @profiles.has_key?('config') ? @profiles['config'] : nil
      log_path = @config['log_path'] || '~/.dabcup/dabcup.log'
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
        $stderr.puts("Invalid log level '#{log_level}, use error level instead")
        log_level = Logger::ERROR
      end
      
      logger = Logger.new(log_path, log_age, log_size)
      logger.level = log_level if log_level
      logger.datetime_format = log_datetime_format if log_datetime_format
      Dabcup::set_logger(logger)
    end
    
    def initialize_storages
      @storages = @profiles.has_key?('storages') ? @profiles['storages'] : nil
      Dabcup::Storage::Factory::storages_config = @storages
    end
    
    def main(args)
      if args.size < 1
        $stderr.puts "Try 'dabcup help'."
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
      raise Dabcup::Error.new("Profile '#{args[0]}' doesn't exist.") if not @profiles.has_key?(args[0])
      operation = Operation::Factory.new_operation(args[1], @profiles[args[0]])
      Dabcup::info("Begin #{args[1]} #{args[0]}")
      operation.run(args)
      Dabcup::info("End #{args[1]} #{args[0]}")
    ensure
      operation.terminate if operation
    end
    
    def help(args)
      puts Dabcup::Help.message(args[1])
    end
  end
end