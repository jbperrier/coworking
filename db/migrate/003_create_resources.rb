class CreateResources < ActiveRecord::Migration
  def self.up
    create_table :resources do |t|
      t.column :name, :string
      t.column :description, :text
    end
    create_table :resources_spaces do |t|
      t.column :resource_id, :integer
      t.column :space_id, :integer
    end
    remove_column :resources_spaces, :id
  end

  def self.down
    drop_table :resources
    drop_table :resources_spaces
  end
end
