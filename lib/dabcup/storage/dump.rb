module Dabcup
  class Storage
    class Dump
      attr_accessor :name
      attr_accessor :size

      def initialize(attrs = {})
        self.name = attrs[:name]
        self.size = attrs[:size]
      end

      def created_at
        Time.parse(name)
      rescue ArgumentError
        nil # Invalid date => ignore file name
      end

      def ==(dump)
        dump && name == dump.name && size == dump.size
      end

      def valid?
        name != '.' and name != '..' and created_at != nil
      end
    end
  end
end

