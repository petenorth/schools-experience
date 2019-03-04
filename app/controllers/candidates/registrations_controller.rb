module Candidates
  class RegistrationsController < ApplicationController
  private

    def persist(model)
      current_registration.save model
    end

    def current_registration
      @current_registration ||= school_session.current_registration
    end

    def school_session
      @school_session ||= Registrations::SchoolSession.new current_urn, session
    end

    def current_urn
      params[:school_id]
    end
  end
end
