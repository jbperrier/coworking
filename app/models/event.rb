class Event < ActiveRecord::Base
  belongs_to :space
  
  def display_date
    self.date.strftime('%A, %B %d')
  end
end
