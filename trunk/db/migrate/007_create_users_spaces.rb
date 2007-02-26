class CreateUsersSpaces < ActiveRecord::Migration
  def self.up
    create_table :spaces_users do |t|
      t.column :user_id, :integer
      t.column :space_id, :integer
    end
    remove_column :spaces_users, :id
  end

  def self.down
    drop_table :spaces_users
  end
end
