module Schools::PlacementDatesHelper
  def placement_date_display_status(val)
    val ? "Open" : "Closed"
  end

  def availability_status_display_status(val)
    val ? "fixed dates" : "flexible dates"
  end

  def placement_date_display_class(val)
    val ? "govuk-tag--available" : "govuk-tag--taken"
  end

  def show_subject_support_option(school)
    options = school.phases.map(&:supports_subjects)

    [true, false].all? { |value| value.in?(options) }
  end

  def placement_date_subject_description(placement_date)
    if placement_date.subject_specific?
      placement_date.subjects.pluck(:name).join(', ')
    elsif placement_date.supports_subjects?
      'All subjects'
    else
      'Primary'
    end
  end
end
