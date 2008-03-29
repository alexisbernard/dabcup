#! /usr/bin/ruby

app_dir = File.dirname(File.dirname(File.expand_path(__FILE__)))
lib_dir = File.join(app_dir, 'lib')
$LOAD_PATH << lib_dir

require 'yaml'
require 'dabcup'

begin
  require 'rubygems'
rescue LoadError => ex
end

app = Dabcup::App.new(app_dir)
app.main(ARGV)