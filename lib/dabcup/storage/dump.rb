module Dabcup
  class Storage
    class Dump
      attr_accessor :name
      attr_accessor :size

      include Dabcup::MassAssignment

      def initialize(attrs = {})
        self.attributes = attrs
      end

      def created_at
        Time.parse(name)
      rescue ArgumentError
        nil # Invalid date => ignore file name
      end

      def ==(dump)
        @name == dump.name and @size == dump.size
      end

      def valid?
        name != '.' and name != '..' and created_at != nil
      end
    end
  end
end

