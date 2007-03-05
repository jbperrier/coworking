class AddAdminToUsersSpaces < ActiveRecord::Migration
  def self.up
    add_column :spaces_users, :admin, :string
    remove_column :spaces_users, :note
  end

  def self.down
    remove_column :spaces_users, :admin
    add_column :spaces_users, :note, :text
  end
end
