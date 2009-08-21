require File.join(File.dirname(__FILE__), 'dabcup_test')

class StorageTest < DabcupTest
  def test_local
    assert(app.profiles['test_local'])
    database = Dabcup::Database::Factory.new_database(app.profiles['test_local']['database'])
    storage = Dabcup::Storage.new(app.profiles['test_local']['storage'])
    test_put_get_delete(database, storage)
  end

  def test_sftp
    assert(app.profiles['test_sftp'])
    database = Dabcup::Database::Factory.new_database(app.profiles['test_sftp']['database'])
    storage = Dabcup::Storage.new(app.profiles['test_sftp']['storage'])
    test_put_get_delete(database, storage)
  end

  # TODO test s3
  # TODO test ftp
  # TODO test clean
  # TODO test clear
  # TODO test mkdirs
  
  protected

  def test_put_get_delete(database, storage)
    file_path = test_dump(database)
    file_name = File.basename(file_path)
    assert(!storage.exists?(file_name))
    # Test put
    old_size = storage.list.size
    storage.put(file_path, file_name)
    assert_equal(storage.list.size, old_size + 1)
    assert(storage.exists?(file_name))
    assert_kind_of(Dabcup::Storage::Dump, dump = storage.find_by_name(file_name))
    # Test get
    tmp_path = File.join(Dir.tmpdir, file_name)
    File.delete(tmp_path) if File.exists?(tmp_path)
    assert(!File.exists?(tmp_path))
    storage.get(file_name, tmp_path)
    assert(File.exists?(tmp_path))
    assert_equal(dump.size, File.size(tmp_path))
    # Test delete
    storage.delete(file_name)
    assert_equal(storage.list.size, old_size)
    assert(!storage.exists?(file_name))
  end

#  def populate(storage, days_before)
#    local_file_path = @dump_name
#    for day_before in (0 .. days_before)
#      remote_file_name = Dabcup::Database::dump_name(@database, Time.now - (day_before * 24 * 3600))
#      storage.put(local_file_path, remote_file_name)
#    end
#  end
end
