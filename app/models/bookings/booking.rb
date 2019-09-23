module Bookings
  class Booking < ApplicationRecord
    belongs_to :bookings_placement_request,
      class_name: 'Bookings::PlacementRequest'

    belongs_to :bookings_subject,
      class_name: 'Bookings::Subject'

    belongs_to :bookings_school,
      class_name: 'Bookings::School'

    has_one :candidate_cancellation, through: :bookings_placement_request
    has_one :school_cancellation, through: :bookings_placement_request

    validates :date,
      presence: true,
      on: :create
    validates :date,
      if: -> { date_changed? },
      timeliness: {
        on_or_after: :today,
        before: -> { 2.years.from_now },
        type: :date
      }

    validates :bookings_placement_request, presence: true
    validates :bookings_placement_request_id, presence: true
    validates :bookings_subject, presence: true
    validates :bookings_school, presence: true
    validates :duration, presence: true, numericality: { greater_than: 0 }

    delegate \
      :availability,
      :degree_stage,
      :degree_stage_explaination,
      :degree_subject,
      :has_dbs_check,
      :objectives,
      :teaching_stage,
      :token,
      :build_candidate_cancellation,
      :closed?,
      :received_on,
      :gitis_contact,
      :contact_uuid,
      :candidate_email,
      :candidate_name,
      to: :bookings_placement_request

    UPCOMING_TIMEFRAME = 2.weeks

    scope :not_cancelled, -> { joins(:bookings_placement_request).merge(PlacementRequest.not_cancelled) }
    scope :upcoming, -> { not_cancelled.accepted.where(arel_table[:date].between(Time.now..UPCOMING_TIMEFRAME.from_now)) }

    scope :accepted, -> { where.not(accepted_at: nil) }
    scope :previous, -> { where(arel_table[:date].lteq(Date.today)) }
    scope :attendance_unlogged, -> { where(attended: nil) }

    def self.from_confirm_booking(confirm_booking)
      new(
        date: confirm_booking.date,
        bookings_subject_id: confirm_booking.bookings_subject_id,
        placement_details: confirm_booking.placement_details
      )
    end

    def status
      bookings_placement_request.status
    end

    def placement_start_date_with_duration
      if bookings_placement_request&.placement_date&.present?
        [date.to_formatted_s(:govuk), 'for', duration_days].join(' ')
      else
        date.to_formatted_s(:govuk)
      end
    end

    def duration_days
      duration.to_s + ' day'.pluralize(duration)
    end

    # stage one of the placement request acceptance mini-wizard
    def booking_confirmed?
      Schools::PlacementRequests::ConfirmBooking.new(
        date: date,
        placement_details: placement_details,
        bookings_subject_id: bookings_subject_id
      ).valid?
    end

    # stage two of the placement request acceptance mini-wizard
    def more_details_added?
      Schools::PlacementRequests::AddMoreDetails.new(
        contact_name: contact_name,
        contact_number: contact_number,
        contact_email:  contact_email,
        location:  location
      ).valid?
    end

    # stage three of the placement request acceptance mini-wizard
    def reviewed_and_candidate_instructions_added?
      Schools::PlacementRequests::ReviewAndSendEmail.new(
        candidate_instructions: candidate_instructions
      ).valid?
    end

    def accepted?
      accepted_at.present?
    end

    def reference
      bookings_placement_request.token.first(5)
    end
  end
end
