class AddCapacityToSpace < ActiveRecord::Migration
  def self.up
    add_column :spaces, :capacity, :integer
  end

  def self.down
    remove_column :spaces, :capacity
  end
end
