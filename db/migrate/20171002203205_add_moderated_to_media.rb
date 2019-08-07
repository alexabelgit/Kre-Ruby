class AddModeratedToMedia < ActiveRecord::Migration[5.0]
  def change
    add_column :media, :moderated, :boolean, null: false, default: false
    add_column :media, :moderation_result, :jsonb
  end
end
