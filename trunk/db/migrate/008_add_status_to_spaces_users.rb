class AddStatusToSpacesUsers < ActiveRecord::Migration
  def self.up
    add_column :spaces_users, :status, :string
  end

  def self.down
    remove_column :spaces_users, :status
  end
end
