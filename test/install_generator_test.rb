# encoding: UTF-8
# Copyright © 2014, 2015, 2016 José Pablo Fernández Silva

require_relative "test_helper"

require "generators/validation_auditor/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests ValidationAuditor::InstallGenerator
  destination File.expand_path("../../tmp", __FILE__)

  should "generate migration" do
    prepare_destination
    run_generator ["validation_auditor:install"]
    migration_dir = File.join(destination_root, "db", "migrate")
    assert File.directory?(migration_dir)
    migration_files = Dir["#{migration_dir}/*"]
    assert_equal 1, migration_files.count
    File.open(migration_files.first) do |migration|
      assert migration.read.include?("create_table :validation_audits")
    end
  end
end

