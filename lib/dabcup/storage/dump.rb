module Dabcup
  class Storage
    class Dump
      IGNORED_NAMES = %w(. ..).freeze

      attr_accessor :name
      attr_accessor :size

      def self.valid_name?(name)
        !IGNORED_NAMES.include?(name)
      end

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
        self.class.valid_name?(name) && created_at != nil
      end
    end
  end
end

