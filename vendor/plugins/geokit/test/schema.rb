ActiveRecord::Schema.define(:version => 0) do
  create_table :companies, :force => true do |t|
    t.column :name, :string
  end  
  
  create_table :locations, :force => true do |t|
    t.column :company_id,  :integer, :default => 0,  :null => false
    t.column :street,      :string,  :limit => 60
    t.column :city,        :string,  :limit => 60
    t.column :state,       :string,  :limit => 2
    t.column :postal_code, :string,  :limit => 16
    t.column :lat,         :decimal, :precision => 15, :scale => 10
    t.column :lng,         :decimal, :precision => 15, :scale => 10
  end
  
  create_table :custom_locations, :force => true do |t|
    t.column :company_id,  :integer, :default => 0,  :null => false
    t.column :street,      :string,  :limit => 60
    t.column :city,        :string,  :limit => 60
    t.column :state,       :string,  :limit => 2
    t.column :postal_code, :string,  :limit => 16
    t.column :latitude,    :decimal, :precision => 15, :scale => 10
    t.column :longitude,   :decimal, :precision => 15, :scale => 10
  end
end