# Todo find a better dir for this
module Schools
  module OnBoarding
    class CurrentStep
      def self.for(school_profile)
        new(school_profile).call
      end

      def initialize(school_profile)
        @school_profile = school_profile
      end

      def call
        if candidate_requirement_required?
          :candidate_requirement
        elsif fees_required?
          :fees
        elsif administration_fee_required?
          :administration_fee
        elsif dbs_fee_required?
          :dbs_fee
        elsif other_fees_required?
          :other_fee
        elsif phases_list_required?
          :phases_list
        elsif key_stage_list_required?
          :key_stage_list
        elsif secondary_subjects_required?
          :secondary_subjects
        elsif college_subjects_required?
          :college_subjects
        else
          raise 'Wizard incomplete' # NOTE: temp until wizard is finished
        end
      end

    private

      def candidate_requirement_required?
        !@school_profile.candidate_requirement.dup.valid?
      end

      def fees_required?
        !@school_profile.fees.dup.valid?
      end

      def administration_fee_required?
        @school_profile.fees.administration_fees &&
          !@school_profile.administration_fee.dup.valid?
      end

      def dbs_fee_required?
        @school_profile.fees.dbs_fees && !@school_profile.dbs_fee.dup.valid?
      end

      def other_fees_required?
        @school_profile.fees.other_fees && !@school_profile.other_fee.dup.valid?
      end

      def phases_list_required?
        !@school_profile.phases_list.dup.valid?
      end

      def key_stage_list_required?
        @school_profile.phases_list.primary
      end

      def secondary_subjects_required?
        @school_profile.phases_list.secondary
      end

      def college_subjects_required?
        @school_profile.phases_list.college
      end
    end
  end
end