class Space < ActiveRecord::Base
  has_many :events
  has_and_belongs_to_many :users
  has_many :reservations
end
