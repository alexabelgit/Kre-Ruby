class CreateEmailEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :email_events do |t|
      t.integer :email_id, null: false
      t.integer :source, null: false, default: 0
      t.integer :timestamp, limit: 8
      t.text :event
      t.text :email
      t.text :'smtp-id'
      t.text :sg_event_id
      t.text :sg_message_id
      t.text :category
      t.text :newsletter
      t.text :response
      t.text :reason
      t.text :ip
      t.text :useragent
      t.text :attempt
      t.text :status
      t.text :type_id
      t.text :url
      t.text :additional_arguments
      t.integer :event_post_timestamp, limit: 8
      t.text :raw
      t.integer :asm_group_id, limit: 2
      t.timestamps
    end
  end
end