module Dabcup
  module Operation
    class List < Base
      def run(args)
        max_length = 0
        main_dumps = @main_storage.list
        spare_dumps = @spare_storage ? @spare_storage.list : []
        # Intersection of main_dumps and spare_dumps
        dumps = main_dumps + spare_dumps.select do |dump| not main_dumps.include?(dump) end
        # Sort dumps by date
        dumps.sort! do |left, right| left.created_at <=> right.created_at end
        # Get length of the longest name
        max_length= (dumps.map {|d| d.name}.max {|l, r| l <=> r} || '').size
        # Prints names, sizes and flags
        dumps.each do |dump|
          name_str = dump.name.ljust(max_length + 2)
          size_str = (dump.size / 1024).to_s.rjust(8)
          location = main_dumps.include?(dump) ? 'M' : ' '
          location += spare_dumps.include?(dump) ? 'S' : ' '
          puts "#{name_str}#{size_str} KB #{location}"
        end
      end
    end
  end
end
