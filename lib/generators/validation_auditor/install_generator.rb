# encoding: UTF-8
# Copyright © 2014, Watu

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module ValidationAuditor
  # Generator to be able to run `rails generate validation_auditor:install`
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), "templates")

    # Create migration files.
    def create_migration_file
      migration_template "migration.rb", "db/migrate/create_validation_audits.rb"
    end

    # Implement the required interface for Rails::Generators::Migration.
    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end
  end
end
