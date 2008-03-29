module Dabcup
  class App
    def initialize(app_dir)
      @app_dir = app_dir
      @info_stream = @err_stream = nil
      profiles_path = File.join(ENV['HOME'], '.dabcup/profiles.yml')
      @profiles = File.open(profiles_path) do |stream| YAML.load(stream) end
      @config = @profiles.has_key?('config') ? @profiles['config'] : nil
      set_output_streams
    end
    
    def main(args)
      raise "Profile #{args[0]} doesn't exist" if not @profiles.has_key?(args[0])
      operation = Operation::Factory.new_operation(args[1], @profiles[args[0]])
      Dabcup::info("Begin #{args[1]} #{args[0]}")
      operation.run(args)
      Dabcup::info("End #{args[1]} #{args[0]}")
    ensure
      operation.terminate
    end
    
    def set_output_streams()
      return if not @config
      return if not @config.has_key?('log')
      info_path = ''
      if @config['log'].has_key?('info')
        info_path = File.expand_path(@config['log']['info'])
        @info_stream = File.new(info_path, 'a')
        Dabcup::info_stream = @info_stream
      end
      if @config['log'].has_key?('err')
        err_path = File.expand_path(@config['log']['err'])
        @err_stream = info_path == err_path ? @info_stream : File.new(err_path, 'a') 
        Dabcup::err_stream=(@err_stream)
      end
    end
    
    def close
      Dabcup::info_stream=($stdout)
      Dabcup::err_stream=($stderr)
      @info_stream.close if @info_stream
      @err_stream.close if @err_stream and @err_stream != @info_stream
    end
  end
end