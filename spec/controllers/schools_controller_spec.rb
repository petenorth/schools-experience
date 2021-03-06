require 'rails_helper'
require Rails.root.join("spec", "controllers", "schools", "session_context")

describe SchoolsController, type: :request do
  describe 'redirecting logged-in users to the dashboard' do
    context 'when no user is logged in' do
      before { get '/schools' }

      specify 'should not be redirected anywhere' do
        expect(response).to render_template :show
      end
    end
  end

  describe '#show' do
    before { get '/schools' }

    specify 'should render the correct template' do
      expect(response).to render_template :show
    end
  end
end
