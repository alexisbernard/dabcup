require File.join(File.dirname(__FILE__), 'dabcup_test')

class DatabaseTest < DabcupTest
  def test_postgresql
    assert(app.profiles['test_postgresql'])
    database = Dabcup::Database::Factory.new_database(app.profiles['test_postgresql']['database'])
    assert_kind_of(Dabcup::Database::PostgreSQL, database)
    file_path = test_dump(database)
    database.restore(file_path) # TODO assert restore
  end

  # TODO test_mysql
  # TODO test failed cases
end
