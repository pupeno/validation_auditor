# frozen_string_literal: true

# Copyright © 2014-2021 José Pablo Fernández Silva

require "rails/generators"
require "rails/generators/migration"
require "rails/generators/active_record"

module ValidationAuditor
  # Generator to be able to run `rails generate validation_auditor:install`
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    source_root File.expand_path("../templates", __FILE__)

    # Create migration files.
    def create_migration_file
      migration_template "migration.rb.erb", "db/migrate/create_validation_audits.rb", migration_version: migration_version
    end

    # Generate next migration number.
    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    # Rails version to inherit ActiveRecord::Migration from.
    def migration_version
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end

    # Respect the type of primary key.
    def migration_primary_key_type_string
      active_record = Rails.configuration.generators.active_record
      active_record ||= Rails.configuration.generators.options[:active_record]
      if active_record[:primary_key_type]
        ", id: :#{active_record[:primary_key_type]}"
      end
    end
  end
end
