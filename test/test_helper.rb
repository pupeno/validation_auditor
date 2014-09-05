# encoding: UTF-8
# Copyright © 2013, 2014, Watu

require "rubygems"

# Test coverage
require "simplecov"
require "coveralls"
SimpleCov.start do
  add_filter "/test/"
end
Coveralls.wear! # Comment out this line to have the local coverage generated.

require "minitest/autorun"
require "minitest/reporters"
MiniTest::Reporters.use!
require "active_support/test_case"
require "action_controller"
require "action_controller/test_case"
require "shoulda"
require "shoulda-context"
require "shoulda-matchers"

# Make the code to be tested easy to load.
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

# Database setup
require "active_record"
require "logger"
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN
ActiveRecord::Base.configurations = {"sqlite3" => {adapter: "sqlite3", database: ":memory:"}}
ActiveRecord::Base.establish_connection("sqlite3")

# Models setup.
require "validation_auditor"
ActiveRecord::Schema.define(version: 0) do
  create_table :audited_records do |t|
    t.string :name
    t.string :email
  end
  create_table :non_audited_records do |t|
    t.string :name
    t.string :email
  end
end
class AuditedRecord < ActiveRecord::Base
  audit_validation_errors
  validates :email, presence: true
end
class NonAuditedRecord < ActiveRecord::Base
  validates :email, presence: true
end
require "generators/validation_auditor/templates/migration"
CreateValidationAudits.migrate("up")

# Shutup.
I18n.enforce_available_locales = false # TODO: remove this line when it's not needed anymore.

require "assert_difference"
class ActiveSupport::TestCase
  include AssertDifference
end
