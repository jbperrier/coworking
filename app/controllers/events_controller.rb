class EventsController < ApplicationController
  def index
    @events = Event.find(:all, :order => 'date desc')
  end
  
  def new
    @spaces = Space.find(:all)
  end
  
  def view
    @event = Event.find(params[:id])
  end
  
  def create
    Event.create!(params[:event])
    redirect_to :action => 'index'
  end
  
  def edit
    @event = Event.find(params[:id])
    @spaces = Space.find(:all)
  end
  
  def update
    Event.find(params[:id]).update_attributes(params[:event])
    redirect_to :action => 'index'
  end
end
