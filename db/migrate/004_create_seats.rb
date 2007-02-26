class CreateSeats < ActiveRecord::Migration
  def self.up
    create_table :seats do |t|
      t.column :space_id, :integer
    end
  end

  def self.down
    drop_table :seats
  end
end
