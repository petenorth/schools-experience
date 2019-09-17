require 'rails_helper'

describe Candidates::Registrations::PlacementRequestsController, type: :request do
  include_context 'Stubbed candidates school'

  let :registration_session do
    FactoryBot.build :registration_session, urn: school.urn
  end

  let :uuid do
    registration_session.uuid
  end

  before do
    Candidates::Registrations::RegistrationStore.instance.store! \
      registration_session

    allow(Candidates::Registrations::CreatePlacementRequestJob).to \
      receive(:perform_later) { true }
  end

  context '#create' do
    before :each do
      @placement_request_count = Bookings::PlacementRequest.count
    end

    context 'uuid not found' do
      before do
        get "/candidates/confirm/bad-uuid"
      end

      it "doesn't create a new PlacementRequest" do
        expect(Bookings::PlacementRequest.count).to \
          eq @placement_request_count
      end

      it "doesn't queue a CreatePlacementRequestJob" do
        expect(Candidates::Registrations::CreatePlacementRequestJob).not_to \
          have_received :perform_later
      end

      it 'renders the session expired view' do
        expect(response).to render_template :session_expired
      end
    end

    context 'uuid found' do
      context 'registration job already enqueued' do
        before do
          get "/candidates/confirm/#{uuid}"
          @placement_request_count = Bookings::PlacementRequest.count
          get "/candidates/confirm/#{uuid}"
        end

        it "doesn't create a new PlacementRequest" do
          expect(Bookings::PlacementRequest.count).to \
            eq @placement_request_count
        end

        it "doesn't requeue a CreatePlacementRequestJob" do
          expect(Candidates::Registrations::CreatePlacementRequestJob).to \
            have_received(:perform_later).exactly(:once)
        end

        it 'redirects to placement request show' do
          expect(response).to redirect_to \
            candidates_school_registrations_placement_request_path(
              school,
              uuid: uuid
            )
        end
      end

      context 'registration job not already enqueued' do
        shared_examples 'a successful create' do
          before do
            expect(fake_gitis).to receive(:create_entity) do |entity_id, _data|
              "#{entity_id}(#{fake_gitis_uuid})"
            end
          end

          include_context 'fake gitis with known uuid'

          before do
            get "/candidates/confirm/#{uuid}"
          end

          let :stored_registration_session do
            Candidates::Registrations::RegistrationStore.instance.retrieve! uuid
          end

          it 'marks the registration as completed and re-stores it in redis' do
            expect(stored_registration_session).to be_completed
          end

          it "creates a candidate" do
            created = Bookings::Candidate.find_by(gitis_uuid: fake_gitis_uuid)
            expect(created).not_to be_nil
          end

          it "assigns contact attrs" do
            expect(session['gitis_contact']).to include \
              'firstname' => stored_registration_session.personal_information.first_name,
              'lastname' => stored_registration_session.personal_information.last_name
          end

          it 'enqueues the create placement request job' do
            expect(Candidates::Registrations::CreatePlacementRequestJob).to \
              have_received(:perform_later).with \
                uuid,
                fake_gitis_uuid,
                'www.example.com',
                nil
          end

          it 'redirects to placement request show' do
            expect(response).to redirect_to \
              candidates_school_registrations_placement_request_path(
                school,
                uuid: uuid
              )
          end
        end

        context 'school has changed availability type' do
          let :registration_session do
            FactoryBot.build :registration_session, :with_placement_date, urn: school.urn
          end

          before do
            school.update! availability_preference_fixed: true
          end

          it_behaves_like 'a successful create'
        end

        context 'school has not changed availability type' do
          it_behaves_like 'a successful create'
        end

        context 'with an invalid session' do
          let :incomplete_registration_session do
            FactoryBot.build :registration_session,
              urn: '333333', uuid: 'aaa', with: [:personal_information]
          end

          before do
            Candidates::Registrations::RegistrationStore.instance.store! \
              incomplete_registration_session

            get "/candidates/confirm/#{incomplete_registration_session.uuid}"
          end

          it 'redirects to the first missing step' do
            expect(response).to redirect_to \
              "/candidates/schools/#{incomplete_registration_session.urn}/registrations/contact_information/new"
          end
        end
      end
    end
  end

  context '#show' do
    before do
      get \
        "/candidates/schools/#{school.urn}/registrations/placement_request?uuid=#{uuid}"
    end

    it 'renders the show template' do
      expect(response).to render_template :show
    end
  end
end
