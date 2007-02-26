class CreateSpaces < ActiveRecord::Migration
  def self.up
    create_table :spaces do |t|
      t.column :name, :string
      t.column :address, :string
      t.column :description, :text
      t.column :hours, :string
    end
  end

  def self.down
    drop_table :spaces
  end
end
