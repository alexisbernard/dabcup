require 'time'
require 'net/ftp'
require 'fileutils'

require 'dabcup/storage/driver/base'
require 'dabcup/storage/driver/local'
require 'dabcup/storage/driver/sftp'
require 'dabcup/storage/driver/ftp'
require 'dabcup/storage/driver/s3'

require 'dabcup/storage/dump'
require 'dabcup/storage/rules'

module Dabcup
  class Storage
    attr_reader :rules, :driver

    def initialize(url)
      @driver = Driver.build(url)
    end 

    def path
      @driver.path
    end

    def disconnect
      @driver.disconnect
    end

    def local?
      @driver.local?
    end

    def put(local_path, remote_name)
      Dabcup::info("put #{local_path} to #{@driver.uri}")
      @driver.put(local_path, remote_name)
    end

    def get(remote_name, local_path)
      Dabcup::info("get #{@driver.uri} to #{local_path}")
      @driver.get(remote_name, local_path)
    end

    def list
      Dabcup::info("list #{@driver.uri}")
      @driver.list.inject([]) do |dumps, dump|
        dumps << dump if dump.valid?
        dumps
      end
    end
    
    def delete(dump_or_string_or_array)
      file_names = array_of_dumps_names(dump_or_string_or_array)
      file_names.each do |file_name|
        Dabcup::info("delete #{@driver.uri}")
        @driver.delete(file_name)
      end
    end
    
    def clear
      delete(list)
    end
    
    def exists?(name)
      list.any? { |dump| dump.name == name }
    end
    
    def dump_name?(name)
      return false
    end

    def find_by_name(file_name)
      list.find { |dump| dump.name == file_name }
    end
    
    def name
      "#{@login}@#{@host}:#{port}:#{@path}"
    end
    
    def default_port(port)
      @port = port if @port.nil? or @port.empty?
    end
    
    # Returns an array of String representing dumps names.
    # If the argument is an array it must contains only String or Dump objects.
    def array_of_dumps_names(dump_or_string_or_array)
      case dump_or_string_or_array
      when String
        [dump_or_string_or_array]
      when Dump
        [dump_or_string_or_array.name]
      when Array
        dump_or_string_or_array.map do |dump_or_string|
          case dump_or_string
          when String
            dump_or_string
          when Dump
            dump_or_string.name
          else
            raise ArgumentError.new("Expecting an array of String or Dump instead of #{dump_or_string.class}")
          end
        end
      else
        raise ArgumentError.new("Expecting a String or Dump or and Array instead of #{dump_or_string_or_array.class}")
      end
    end
  end
end
