class Dabcup::Test::Database < Dabcup::Test::Base
  def initialize(attributes)
    super(attributes)
    @dump_name = Dabcup::Database.dump_name(@database)
  end
  
  def define_cases
    add_case(:name => 'dump', :description => "Dump a database.")
    add_case(:name => 'restore', :description => "Restore a database.")
  end
  
  def dump()
    File.delete(@dump_name) if File.exists?(@dump_name)
    @database.dump(@dump_name)
    raise "Dump '#{@dump_name}' not created." if not File.exists?(@dump_name)
    raise "Dump '#{@dump_name}' is empty." if File.size(@dump_name) < 1
  end
  
  def restore()
    @database.restore(@dump_name)
  end
end
