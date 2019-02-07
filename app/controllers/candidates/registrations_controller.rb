module Candidates
  class RegistrationsController < ApplicationController
  private

    def persist(model)
      current_registration[model.model_name.param_key] = model.attributes
    end

    def current_registration
      session[:registration] ||= {}
    end

    def current_urn
      params[:school_id]
    end
  end
end
