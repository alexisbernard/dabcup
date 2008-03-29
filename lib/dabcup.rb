module Dabcup
  # Default output streams
  @@info_stream = $stdout
  @@err_stream = $stderr
  
  def self.info(msg)
    @@info_stream.puts Time.now.strftime('[%Y-%m-%d %H:%M] ') + msg
  end
  
  def self.error(msg)
    @@err_stream.puts Time.now.strftime('[%Y-%m-%d %H:%M] ') + msg
  end
  
  def self.info_stream=(stream)
    @@info_stream = stream
  end
  
  def self.err_stream=(stream)
    @@err_stream = stream
  end
end

require 'tmpdir'
require 'dabcup/app'
require 'dabcup/database'
require 'dabcup/storage'
require 'dabcup/operation'


