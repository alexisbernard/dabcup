require 'dabcup/operation/base'
require 'dabcup/operation/clean'
require 'dabcup/operation/clear'
require 'dabcup/operation/remove'
require 'dabcup/operation/get'
require 'dabcup/operation/list'
require 'dabcup/operation/populate'
require 'dabcup/operation/restore'
require 'dabcup/operation/dump'

module Dabcup
  module Operation
    def self.build(name, config)
      case name
      when 'dump' then Dabcup::Operation::Dump.new(config)
      when 'restore' then Dabcup::Operation::Restore.new(config)
      when 'list' then Dabcup::Operation::List.new(config)
      when 'get' then Dabcup::Operation::Get.new(config)
      when 'remove' then Dabcup::Operation::Remove.new(config)
      when 'clear' then Dabcup::Operation::Clear.new(config)
      when 'clean' then Dabcup::Operation::Clean.new(config)
      when 'populate' then Dabcup::Operation::Populate.new(config)
      when 'test' then Dabcup::Operation::Test.new(config)
      else
        raise Dabcup::Error.new("Unknow operation '#{name}'.")
      end
    end
  end
end
