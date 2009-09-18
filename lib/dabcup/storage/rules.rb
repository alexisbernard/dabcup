module Dabcup
  class Storage
    # Rules
    class Rules
      attr_reader :days_of_week
      attr_reader :days_of_month
      attr_reader :less_days_than

      # remove_older_than: <n>[Y|M|D]
      # keep_younger_than: <n>[Y|M|D]
      # keep_days_of_month: <n>
      # keep_days_of_week: <n>
      # keep_hours: <n>

      # Rules result
      KEEP = 0
      REMOVE = 1
      DEFAULT = 3
      NOTHING = 4

      UNITS = {
        'Y' => 3600 * 24 * 365,
        'M' => 3600 * 24 * 30,
        'W' => 3600 * 24 * 7,
        'D' => 3600 * 24
      }

      def initialize(rules)
        self.instructions = rules
      end

      def apply(dump)
        @now = Time.now
        case @instructions
        when Hash
          result = apply_instructions(@instructions, dump)
        when Array
          @instructions.each do |rules|
            result = apply_instructions(rules, dump)
            break if result != NOTHING
          end
        else
          raise ArgumentError.new("Expecting a Hash or an Array instead of a #{@instructions.class}.")
        end
        result
      end

      def apply_instructions(instructions, dump)
        instructions.each do |instruction, value|
          case instruction
          when 'remove_older_than'
            return REMOVE if @now - dump.created_at > age_to_seconds(value)
          # TODO Is this rule really necessary?
          #when 'keep_younger_than'
          #  return KEEP if @now - dump.created_at < age_to_seconds(value)
          when 'keep_days_of_month'
            value = [value] if not value.is_a?(Array)
            return KEEP if value.include?(dump.created_at.mday)
          when 'keep_days_of_week'
            value = [value] if not value.is_a?(Array)
            return KEEP if value.include?(dump.created_at.wday)
          when 'keep_hours'
            value = [value] if not value.is_a?(Array)
            return KEEP if value.include?(dump.created_at.hour)
          else
            raise Dabcup::Error.new("Unknow rule instruction '#{instruction}'.")
          end
        end
        NOTHING
      end

      def age_to_seconds(age)
        raise Dabcup::Error.new("Unknow unit '#{age[-1,1]}.") if not UNITS[age[-1,1]]
        age.to_i * UNITS[age[-1,1]]
      end

      def instructions=(instructions)
        if not [Array, Hash].include?(instructions.class)
          raise ArgumentError.new("Expecting a Hash or an Array instead of a #{@instructions.class}.")
        end
        @instructions = instructions
      end
    end
  end
end