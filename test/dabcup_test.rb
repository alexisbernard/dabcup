require 'test/unit'
require 'pathname'

app_dir = Pathname.new(__FILE__).realpath().dirname().dirname()
lib_dir = File.join(app_dir, 'lib')
$LOAD_PATH << lib_dir

require 'dabcup'

class DabcupTest < Test::Unit::TestCase
  def app
    @app ||= Dabcup::App.new('.')
  end

  def default_test
  end

  protected

  def test_dump(database)
    file_path = File.join(Dir.tmpdir, Dabcup::Database.dump_name(database))
    File.delete(file_path) if File.exists?(file_path)
    assert(!File.exists?(file_path)) # Dump file should not exists
    database.dump(file_path)
    assert(File.exists?(file_path))
    file_path
  end
end