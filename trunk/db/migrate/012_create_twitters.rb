class CreateTwitters < ActiveRecord::Migration
  def self.up
    create_table :twitters do |t|
    end
  end

  def self.down
    drop_table :twitters
  end
end
