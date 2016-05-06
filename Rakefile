# encoding: UTF-8
# Copyright © 2014, 2015, 2016 José Pablo Fernández Silva

require "rubygems"
require "bundler/setup"
require "bundler/gem_tasks"

require "rake/testtask"
Rake::TestTask.new do |t|
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
