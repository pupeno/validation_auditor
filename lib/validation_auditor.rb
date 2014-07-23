# encoding: UTF-8
# Copyright © 2012, 2013, 2014, Watu

require "validation_auditor/version"
require "active_record"
require "action_controller"

module ValidationAuditor
  class ValidationAudit < ActiveRecord::Base
    belongs_to :record, :polymorphic => true

    serialize :failures, Hash
    serialize :failure_messages, Array
    serialize :data, Hash
    serialize :params, Hash


    if respond_to? :attr_accessible # For Rails < 4 or Rails >= 4 with attr_accessible added by a third party library.
      begin
        attr_accessible
      rescue RuntimeError # Rails 4 raises a RuntimeError when you call attr_accessible, but we still want to call it in case you added attr_accessible gem.
      end
    end
  end

  module Controller
    extend ActiveSupport::Concern

    module ClassMethods
      def audit_validation_errors
        before_filter :make_request_auditable
      end
    end

    def make_request_auditable
      Thread.current[:validation_auditor_request] = self.request
    end

    def self.request
      Thread.current[:validation_auditor_request]
    end
  end

  module Model
    extend ActiveSupport::Concern

    module ClassMethods
      def audit_validation_errors
        after_rollback :audit_validation
      end
    end

    def audit_validation
      if !errors.empty? # We don't use :valid? to avoid re-running validations
        va = ValidationAudit.new
        va.failures = self.errors.to_hash
        va.failure_messages = self.errors.full_messages.to_a
        va.data = self.attributes
        if self.new_record? # For new records
          va.record_type = self.class.name # we only store the class's name.
        else
          va.record = self
        end
        if ValidationAuditor::Controller.request.present?
          request = ValidationAuditor::Controller.request
          va.params = request.params
          va.url = request.url
          va.user_agent = request.env["HTTP_USER_AGENT"]
        end
        va.save
      end
    end
  end
end

ActionController::Base.send(:include, ValidationAuditor::Controller)
ActiveRecord::Base.send(:include, ValidationAuditor::Model)
