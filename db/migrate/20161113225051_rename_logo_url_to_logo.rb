class RenameLogoUrlToLogo < ActiveRecord::Migration[5.0]
  def change
    rename_column :stores, :logo_url, :logo
  end
end
