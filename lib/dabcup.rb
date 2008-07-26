module Dabcup
  def self.debug(msg)
    return if not @@logger
    @@logger.debug(normalize_message(msg))
  end
  
  def self.info(msg)
    return if not @@logger
    @@logger.info(normalize_message(msg))
  end
  
  def self.warn(msg)
    return if not @@logger
    @@logger.warn(normalize_message(msg))
  end
  
  def self.error(msg)
    return if not @@logger
    @@logger.error(normalize_message(msg))  
  end
  
  def self.fatal(msg)
    return if not @@logger
    @@logger.fatal(normalize_message(msg))
  end
  
  def self.set_logger(logger)
    @@logger = logger
  end
  
  def self.get_logger()
    @@logger
  end
  
  def self.normalize_message(msg)
    msg.kind_of?(Exception) ? msg.inspect + "\n  " + msg.backtrace.join("\n  ") : msg
  end
  
  def self.time_to_name(time)
    time.strftime('%Y-%m-%dT%H:%M:%S') + '.dump'
  end
  
  class Error < StandardError
  end
end

require 'tmpdir'
require 'dabcup/util'
require 'dabcup/profile'
require 'dabcup/app'
require 'dabcup/database'
require 'dabcup/storage'
require 'dabcup/operation'
require 'dabcup/help'


