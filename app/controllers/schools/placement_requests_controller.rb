module Schools
  class PlacementRequestsController < Schools::BaseController
    def index
      @placement_requests = placement_requests
    end

    def show
      @placement_request = placement_request
      @placement_request.viewed!
    end

  private

    def placement_requests
      current_school
        .placement_requests
        .eager_load(:candidate_cancellation, :school_cancellation, :placement_date)
    end

    def placement_request
      current_school.placement_requests.find params[:id]
    end
  end
end
