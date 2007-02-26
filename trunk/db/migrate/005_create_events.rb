class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :date, :date
      t.column :space_id, :integer
    end
  end

  def self.down
    drop_table :events
  end
end
