# Persists the non personally identifiable information from a candidates
# registration
module Bookings
  class PlacementRequest < ApplicationRecord
    include ViewTrackable
    include Candidates::Registrations::Behaviours::PlacementPreference
    include Candidates::Registrations::Behaviours::Education
    include Candidates::Registrations::Behaviours::TeachingPreference
    include Candidates::Registrations::Behaviours::BackgroundCheck

    has_secure_token

    validates_presence_of :candidate, unless: :pre_phase3_record?

    belongs_to :school,
      class_name: 'Bookings::School',
      foreign_key: :bookings_school_id

    belongs_to :candidate,
      class_name: 'Bookings::Candidate',
      foreign_key: :candidate_id,
      optional: true

    has_one :booking,
      class_name: 'Bookings::Booking',
      foreign_key: 'bookings_placement_request_id',
      inverse_of: :bookings_placement_request

    belongs_to :placement_date,
      class_name: 'Bookings::PlacementDate',
      foreign_key: :bookings_placement_date_id,
      optional: true

    has_one :candidate_cancellation,
      -> { where cancelled_by: 'candidate' },
      class_name: 'Bookings::PlacementRequest::Cancellation',
      foreign_key: 'bookings_placement_request_id',
      inverse_of: :placement_request,
      dependent: :destroy

    has_one :school_cancellation,
      -> { where cancelled_by: 'school' },
      class_name: 'Bookings::PlacementRequest::Cancellation',
      foreign_key: 'bookings_placement_request_id',
      inverse_of: :placement_request,
      dependent: :destroy

    scope :unprocessed, -> do
      not_cancelled.merge unbooked
    end

    scope :unbooked, -> do
      without_booking.or booking_not_sent
    end

    scope :booking_not_sent, -> do
      left_joins(:booking).where(bookings_bookings: { accepted_at: nil })
    end

    scope :without_booking, -> do
      left_joins(:booking)
        .where(bookings_bookings: { bookings_placement_request_id: nil })
    end

    scope :cancelled, -> do
      left_joins(:candidate_cancellation, :school_cancellation)
        .where <<~SQL
          bookings_placement_request_cancellations.sent_at IS NOT NULL
          OR school_cancellations_bookings_placement_requests.sent_at IS NOT NULL
        SQL
    end

    scope :not_cancelled, -> do
      left_joins(:candidate_cancellation, :school_cancellation)
        .where(bookings_placement_request_cancellations: { sent_at: nil })
        .where(school_cancellations_bookings_placement_requests: { sent_at: nil })
    end

    scope :with_unviewed_canidate_cancellation, -> do
      left_joins(:candidate_cancellation)
        .merge Cancellation.unviewed
    end

    scope :not_cancelled_by_school, -> do
      left_joins(:school_cancellation)
        .where(school_cancellations_bookings_placement_requests: { bookings_placement_request_id: nil })
    end

    scope :requiring_attention, -> do
      without_booking
        .with_unviewed_canidate_cancellation
        .not_cancelled_by_school
    end

    default_scope { where.not(candidate_id: nil) }

    delegate :gitis_contact, :fetch_gitis_contact, to: :candidate

    def self.create_from_registration_session!(registration_session, analytics_tracking_uuid = nil, context: nil)
      self.new(
        Candidates::Registrations::RegistrationAsPlacementRequest
          .new(registration_session)
          .attributes
          .merge(analytics_tracking_uuid: analytics_tracking_uuid)
      ).tap { |r| r.save!(context: context) }
    end

    def sent_at
      created_at
    end

    def closed?
      cancelled? || completed?
    end

    def open?
      !closed?
    end

    def contact_uuid
      candidate.gitis_uuid
    end

    def dates_requested
      if placement_date.present?
        placement_date.date.to_formatted_s(:govuk)
      else
        availability
      end
    end

    def received_on
      created_at.to_date
    end

    # FIXME SE-1130
    def status
      return 'Cancelled' if cancelled?

      'New'
    end

    def dbs
      if has_dbs_check?
        'Yes'
      else
        'No'
      end
    end

    def teaching_subjects
      [subject_first_choice, subject_second_choice]
    end

    def school_email
      school.notification_emails
    end

    def school_name
      school.name
    end

    def school_urn
      school.urn
    end

    def candidate_email
      candidate.email
    end

    def candidate_name
      candidate.full_name
    end

    def cancellation
      candidate_cancellation || school_cancellation
    end

    def cancelled?
      cancellation&.sent?
    end

    def requested_on
      created_at&.to_date
    end

  private

    def completed?
      # FIXME SE-1096 determine from booking
      false
    end

    def pre_phase3_record?
      persisted? && candidate_id_was.nil?
    end
  end
end
