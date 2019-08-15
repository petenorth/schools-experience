module Bookings::Gitis
  module FakeCrm
    def initialize(*args)
      super
      @fake_backend = Backends::Fake.new
    end

    def fake_backend
      @fake_backend
    end

    def fake_contact_id
      fake_backend.send(:fake_contact_id)
    end

    def fake_contact_data
      fake_backend.send(:fake_contact_data)
    end

    def backend
      stubbed? ? @fake_backend : @backend
    end

    def find_by_email(address)
      return super unless stubbed?
      return nil if address =~ /unknown/

      Contact.new(fake_contact_data).tap do |contact|
        contact.email = address
      end
    end

    def find_contact_for_signin(email:, firstname:, lastname:, date_of_birth:)
      return super unless stubbed?
      return nil if email =~ /unknown/

      Contact.new(fake_contact_data).tap do |contact|
        contact.email = email
      end
    end

  private

    def stubbed?
      Rails.application.config.x.gitis.fake_crm
    end
  end
end
