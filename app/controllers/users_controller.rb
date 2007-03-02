class UsersController < ApplicationController
  def view
    @user = User.find(params[:id])
  end
end
