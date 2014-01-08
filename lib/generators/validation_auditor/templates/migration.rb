class CreateValidationAudits < ActiveRecord::Migration
  def up
    create_table :validation_audits do |t|
      t.integer :record_id
      t.string :record_type
      t.text :failure_messages
      t.text :failures
      t.text :data
      t.text :params
      t.text :url
      t.text :user_agent
      t.timestamps
    end

    add_index :validation_audits, :created_at
  end
end
