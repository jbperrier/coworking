class AddNoteToSpacesUsers < ActiveRecord::Migration
  def self.up
    add_column :spaces_users, :note, :text
  end

  def self.down
    remove_column :spaces_users, :note
  end
end
