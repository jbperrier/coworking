require File.dirname(__FILE__) + '/../test_helper'
require 'seats_controller'

# Re-raise errors caught by the controller.
class SeatsController; def rescue_action(e) raise e end; end

class SeatsControllerTest < Test::Unit::TestCase
  def setup
    @controller = SeatsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
