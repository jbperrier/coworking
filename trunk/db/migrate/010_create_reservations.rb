class CreateReservations < ActiveRecord::Migration
  def self.up
    create_table :reservations do |t|
      t.column :date, :date
      t.column :user_id, :integer
      t.column :space_id, :integer
      t.column :note, :text
    end
  end

  def self.down
    drop_table :reservations
  end
end
