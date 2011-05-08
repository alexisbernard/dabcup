#! /usr/bin/env ruby

require 'pathname'

app_dir = Pathname.new(__FILE__).realpath().dirname().dirname()
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
