class Notify
  attr_accessor :to

  def initialize(to:)
    self.to = Array.wrap to
  end

  def despatch!
    to.each do |address|
      NotifyJob.perform_later \
        to: address,
        template_id: template_id,
        personalisation_json: personalisation.to_json
    end
  end

  alias_method :despatch_later!, :despatch!

private

  def template_id
    fail 'Not implemented'
  end

  def personalisation
    fail 'Not implemented'
  end
end
