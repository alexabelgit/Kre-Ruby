class CreateAbuseReports < ActiveRecord::Migration[5.0]
  def change
    create_table :abuse_reports do |t|
      t.integer    :reason,   null: false
      t.integer    :source,   null: false
      t.references :abusable, null: false, polymorphic: true

      t.timestamps
    end
  end
end
