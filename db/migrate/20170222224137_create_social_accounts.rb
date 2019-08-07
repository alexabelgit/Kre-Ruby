class CreateSocialAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false
      t.integer :provider, null: false
      t.string :uid, null: false
      t.string :access_token, null: false

      t.timestamps
    end

    add_index :social_accounts, [:user_id, :provider], unique: true
  end
end
