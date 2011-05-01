module Dabcup
  def self.time_to_name(time)
    time.strftime('%Y-%m-%dT%H:%M:%S') + '.dump'
  end
  
  class Error < StandardError
  end
end

require 'tmpdir'

require 'dabcup/app'
require 'dabcup/database'
require 'dabcup/storage'
require 'dabcup/operation'
require 'dabcup/help'
