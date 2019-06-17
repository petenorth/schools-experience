module Bookings::Gitis
  module FakeCrm
    def find(*ids)
      ids = normalise_ids(*ids)
      validate_ids(ids)

      if ids.length == 1
        Contact.new(fake_account_data.merge('contactid' => ids[0]))
      else
        ids.map do |id|
          Contact.new(fake_account_data.merge('contactid' => id))
        end
      end
    end

    def find_by_email(address)
      Contact.new(fake_account_data).tap do |contact|
        contact.email = address
      end
    end

  private

    def write_data(crm_contact_data)
      crm_contact_data['contactid'].presence ||
        "75c5a32d-d603-4483-956f-236fee7c5784"
    end

    def fake_account_data
      {
        'contactid' => "d778d663-a022-4c4b-9962-e469ee179f4a",
        'firstname' => 'Matthew',
        'lastname' => 'Richards',
        'mobilephone' => '07123 456789',
        'telephone1' => '01234 567890',
        'emailaddress1' => 'first@thisaddress.com',
        'emailaddress2' => 'second@thisaddress.com',
        'emailaddress3' => 'third@thisaddress.com',
        'address1_line1' => 'First Line',
        'address1_line2' => 'Second Line',
        'address1_line3' => 'Third Line',
        'address1_city' => 'Manchester',
        'address1_stateorprovince' => 'Manchester',
        'address1_postalcode' => 'MA1 1AM'
      }
    end
  end
end
