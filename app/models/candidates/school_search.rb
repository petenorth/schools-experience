module Candidates
  class SchoolSearch
    include ActiveModel::Model

    DISTANCES = [
      [1, '1 mile'],
      [3, '3 miles'],
      [5, '5 miles'],
      [10, '10 miles'],
      [15, '15 miles'],
      [20, '20 miles'],
      [25, '25 miles']
    ].freeze

    FEES = [
      ['', 'None'],
      ['30', 'up to £30'],
      ['60', 'up to £60'],
      ['90', 'up to £90']
    ].freeze

    attr_accessor :query, :location
    attr_reader :distance, :subjects, :phases, :max_fee

    class << self
      def fees
        FEES
      end

      def distances
        DISTANCES
      end
    end

    def distance=(dist_ids)
      @distance = dist_ids.present? ? dist_ids.to_i : nil
    end

    def subjects=(subj_ids)
      @subjects = Array.wrap(subj_ids).map(&:presence).compact.map(&:to_i)
    end

    def phases=(phase_ids)
      @phases = Array.wrap(phase_ids).map(&:presence).compact.map(&:to_i)
    end

    def max_fee=(max_f)
      max_f = max_f.to_s.strip
      @max_fee = FEES.map(&:first).include?(max_f) ? max_f : ''
    end

    def results
      school_search.results
    end

    def valid_search?
      query.present? || (location.present? && distance.present?)
    end

    def filtering_results?
      valid_search?
    end

    def total_results
      0
    end

  private

    def school_search
      Bookings::SchoolSearch.new(
        query,
        location: location,
        radius: distance,
        subjects: subjects,
        phases: phases,
        max_fee: max_fee
      )
    end
  end
end