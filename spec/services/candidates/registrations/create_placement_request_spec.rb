require 'rails_helper'

describe Candidates::Registrations::CreatePlacementRequest do
  include_context 'Stubbed candidates school'
  include_context 'fake gitis with known uuid'

  let(:host) { 'example.com' }

  let :school do
    create :bookings_school, \
      name: 'Test School',
      contact_email: 'test@test.com',
      urn: school_urn
  end

  let(:registration_uuid) { SecureRandom.urlsafe_base64 }

  let :registration_store do
    Candidates::Registrations::RegistrationStore.instance
  end

  let :registration_session do
    FactoryBot.build :registration_session, urn: school.urn, uuid: registration_uuid
  end

  let :personal_information do
    registration_session.personal_information
  end

  let :school_request_confirmation_notification_link_only do
    double NotifyEmail::SchoolRequestConfirmationLinkOnly, despatch_later!: true
  end

  let :candidate_request_confirmation_notification_with_confirmation_link do
    double NotifyEmail::CandidateRequestConfirmationNoPii,
      despatch_later!: true
  end

  let :cancellation_url do
    %r{\Ahttps://example.com/candidates/cancel/\w{24}\z}
  end

  let :placement_request_url do
    %r{\Ahttps://example.com/schools/placement_requests/\d+\z}
  end

  let :application_preview do
    Candidates::Registrations::ApplicationPreview.new registration_session
  end

  describe '#create!' do
    before do
      @placement_request_count = Bookings::PlacementRequest.count

      allow(NotifyEmail::SchoolRequestConfirmationLinkOnly).to \
        receive(:new) { school_request_confirmation_notification_link_only }

      allow(NotifyEmail::CandidateRequestConfirmationNoPii).to \
        receive(:from_application_preview) { candidate_request_confirmation_notification_with_confirmation_link }

      allow(Bookings::LogToGitisJob).to \
        receive(:perform_later).and_return(true)

      allow(Candidates::Registrations::AcceptPrivacyPolicyJob).to \
        receive(:perform_later).and_return(true)

      allow(fake_gitis).to receive(:find).and_call_original
      allow(fake_gitis.store).to receive(:update_entity).and_call_original
      allow(fake_gitis.store).to receive(:create_entity).and_call_original
    end

    subject do
      described_class.new \
        fake_gitis, registration_uuid, signedin_contactid, host, SecureRandom.uuid
    end

    shared_examples 'create placement request' do
      it "creates placment request" do
        expect(Bookings::PlacementRequest.count).to \
          eq @placement_request_count + 1

        latest = Bookings::PlacementRequest.last
        expect(latest.school.urn).to eq school_urn
        expect(latest.candidate.gitis_uuid).to eq requests_contactid
      end
    end

    shared_examples 'send emails' do
      it "notifies the school" do
        expect(NotifyEmail::SchoolRequestConfirmationLinkOnly).to \
          have_received(:new).with \
            to: school.notification_emails,
            school_name: school.name,
            placement_request_url: placement_request_url

        expect(school_request_confirmation_notification_link_only).to \
          have_received :despatch_later!
      end

      it "notifies the candidate" do
        expect(NotifyEmail::CandidateRequestConfirmationNoPii).to \
          have_received(:from_application_preview).with \
            registration_session.email,
            application_preview,
            cancellation_url

        expect(
          candidate_request_confirmation_notification_with_confirmation_link
        ).to have_received :despatch_later!
      end
    end

    shared_examples 'remove from registration session' do
      it 'deletes the registration session from redis' do
        expect { registration_store.retrieve! registration_session.uuid }.to \
          raise_error Candidates::Registrations::RegistrationStore::SessionNotFound
      end
    end

    shared_examples 'schedule gitis jobs' do
      it "schedules accepting the privacy policy" do
        expect(Candidates::Registrations::AcceptPrivacyPolicyJob).to \
          have_received(:perform_later).with \
            requests_contactid,
            Bookings::Gitis::PrivacyPolicy.default
      end

      it 'schedules the log to gitis' do
        expect(Bookings::LogToGitisJob).to \
          have_received(:perform_later).with \
            requests_contactid,
            %r{#{Date.today.to_formatted_s(:gitis)} REQUEST}
      end
    end

    context 'with known registration uuid' do
      before { registration_store.store! registration_session }

      context 'but without gitis contactid and unknown email address' do
        let(:requests_contactid) { fake_gitis_uuid }
        let(:signedin_contactid) { nil }

        before do
          allow(fake_gitis).to \
            receive(:find_contact_for_signin).and_return(nil)

          subject.create!
        end

        it "does not retrieve the contact from gitis byt id" do
          expect(fake_gitis).not_to have_received(:find)
        end

        it "searches for the contact in gitis using PersonalInformation" do
          expect(fake_gitis).to \
            have_received(:find_contact_for_signin).with \
              email: personal_information.email,
              firstname: personal_information.first_name,
              lastname: personal_information.last_name,
              date_of_birth: personal_information.date_of_birth
        end

        it "creates a contact in gitis" do
          expect(fake_gitis.store).to have_received(:create_entity).with \
            'contacts',
            hash_including(
              'firstname' => personal_information.first_name,
              'lastname' => personal_information.last_name
            )
        end

        it "does not update a contact in gitis" do
          expect(fake_gitis.store).not_to have_received(:update_entity)
        end

        it "creates a new Candidate record" do
          candidates = Bookings::Candidate.where(gitis_uuid: fake_gitis_uuid)
          expect(candidates.count).to eql(1)
        end

        include_examples 'create placement request'
        include_examples 'send emails'
        include_examples 'remove from registration session'
        include_examples 'schedule gitis jobs'
      end

      context 'but without gitis contactid but known email address' do
        let(:requests_contactid) { fake_gitis_uuid }
        let(:signedin_contactid) { nil }

        before do
          allow(fake_gitis).to \
            receive(:find_contact_for_signin).and_call_original

          subject.create!
        end

        it "does not retrieve the contact from gitis" do
          expect(fake_gitis).not_to have_received(:find)
        end

        it "searches for the contact in gitis using PersonalInformation" do
          expect(fake_gitis).to \
            have_received(:find_contact_for_signin).with \
              email: personal_information.email,
              firstname: personal_information.first_name,
              lastname: personal_information.last_name,
              date_of_birth: personal_information.date_of_birth
        end

        it "does not create a contact in gitis" do
          expect(fake_gitis.store).not_to have_received(:create_entity)
        end

        it "does update a contact in gitis" do
          expect(fake_gitis.store).to have_received(:update_entity).with \
            "contacts(#{fake_gitis_uuid})",
            hash_including('address1_city' => 'Test town')
        end

        it "creates a new Candidate record" do
          candidates = Bookings::Candidate.where(gitis_uuid: fake_gitis_uuid)
          expect(candidates.count).to eql(1)
        end

        include_examples 'create placement request'
        include_examples 'send emails'
        include_examples 'remove from registration session'
        include_examples 'schedule gitis jobs'
      end

      context 'and known gitis contactid' do
        let(:contact) { build(:gitis_contact, :persisted) }
        let(:requests_contactid) { contact.id }
        let(:signedin_contactid) { contact.id }

        before { subject.create! }

        it "retrieves the contact from gitis" do
          expect(fake_gitis).to have_received(:find).with(requests_contactid)
        end

        it "updates the contact in gitis" do
          expect(fake_gitis.store).to have_received(:update_entity).with \
            contact.entity_id,
            hash_including('address1_city' => 'Test town')
        end

        it "creates a Candidate record" do
          candidates = Bookings::Candidate.where(gitis_uuid: requests_contactid)
          expect(candidates.count).to eql(1)
        end

        include_examples 'create placement request'
        include_examples 'send emails'
        include_examples 'remove from registration session'
        include_examples 'schedule gitis jobs'
      end

      context 'but unknown gitis contactid' do
        let(:signedin_contactid) { SecureRandom.uuid }

        before do
          allow(fake_gitis).to receive(:find).with(signedin_contactid) {
            raise Bookings::Gitis::API::UnknownUrlError.new OpenStruct.new(
              status: 404,
              headers: {},
              body: 'Unknown contact'
            )
          }
        end

        it 'will raise an exception' do
          expect {
            subject.create!
          }.to raise_exception(Bookings::Gitis::API::UnknownUrlError)

          expect(Bookings::PlacementRequest.count).to be_zero
        end
      end
    end

    context 'with unknown registration uuid' do
      let(:signedin_contactid) { nil }

      it 'will raise an exception' do
        expect {
          subject.create!
        }.to raise_exception(Candidates::Registrations::RegistrationStore::SessionNotFound)
      end
    end
  end
end
