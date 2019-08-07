class AddAccessSecretToSocialAccount < ActiveRecord::Migration[5.0]
  def change
    add_column :social_accounts, :access_secret, :string
  end
end
