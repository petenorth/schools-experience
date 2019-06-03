Given("the school has subjects") do
  @school.subjects << FactoryBot.create(:bookings_subject, name: 'Maths')
  @school.subjects << FactoryBot.create(:bookings_subject, name: 'Physics')
end

Given("there are some upcoming requests") do
  step 'there are some placement requests'
end

Given("there are some placement requests") do
  @placement_requests = FactoryBot.create_list \
    :placement_request,
    5,
    school: @school,
    created_at: '2094-01-01',
    teaching_stage: 'I’ve applied for teacher training',
    availability: 'Any time during July 2094'
end

Given("there is at least one placement request") do
  @placement_request = FactoryBot.create \
    :placement_request,
    school: @school,
    created_at: '2094-02-08',
    availability: 'Any time during November 2019',
    teaching_stage: 'I’ve applied for teacher training',
    has_dbs_check: true,
    objectives: 'To learn different teaching styles and what life is like in a classroom.',
    degree_stage: 'Final year',
    degree_subject: 'Law'
end

When("I am on a placement request page") do
  visit path_for 'placement request', placement_request: @placement_request
end

Then("I should see all the upcoming requests listed") do
  within("#school-requests") do
    expect(page).to have_css('.school-request', count: 5)
  end
end

Then("I should see all the placement requests listed") do
  within("#school-requests") do
    expect(page).to have_css('.school-request', count: 5)
  end
end

Then("the placement listings should have the following values:") do |table|
  within('#school-requests') do
    within(page.all('.school-request').first) do
      table.hashes.each do |row|
        expect(page).to have_css('dt', text: row['Heading'])
        expect(page).to have_css('dd', text: /#{row['Value']}/i)
      end
    end
  end
end

Then("every request should contain a link to view more details") do
  within('#school-requests') do
    page.all('.school-request').each_with_index do |sr, i|
      placement_request = @placement_requests.reverse[i]
      within(sr) do
        expect(page).to have_link('Open request', href: schools_placement_request_path(placement_request.id))
      end
    end
  end
end

Then("every request should contain a title starting with {string}") do |string|
  within('#school-requests') do
    page.all('.school-request').each do |sr|
      within(sr) do
        expect(page).to have_css('h2', text: /#{string}/)
      end
    end
  end
end

Then("I should see a {string} section with the following values:") do |heading, table|
  within("section##{heading.parameterize}") do
    expect(page).to have_css('h2', text: heading)
    table.hashes.each do |row|
      expect(page).to have_css('dt', text: row['Heading'])

      if row['Heading'].match?(/subjects/)
        row['Value'].split(", ").each do |subject|
          expect(page).to have_css('dd', text: /#{subject}/i)
        end
      else
        expect(page).to have_css('dd', text: /#{row['Value']}/i)
      end
    end
  end
end

Then("there should be the following buttons:") do |table|
  # note that button_to inserts a form with a submit input so
  # if we don't find a regular link/button check for that too
  table.transpose.raw.flatten.each do |button_text|
    within('.accept-or-reject') do
      begin
        expect(page).to have_css('.govuk-button', text: button_text)
      rescue RSpec::Expectations::ExpectationNotMetError
        expect(page).to have_css("input.govuk-button[value='#{button_text}']")
      end
    end
  end
end

When("I click {string} on the first request") do |string|
  within('#school-requests') do
    within(page.all('.school-request').first) do
      page.find('summary span', text: string).click
    end
  end
end

Then("I should see the following contact details:") do |table|
  within(page.all('.school-request').first) do
    within('.contact-details dl') do
      table.hashes.each do |row|
        expect(page).to have_css('dt', text: row['Heading'])
        expect(page).to have_css('dd', text: /#{row['Value']}/i)
      end
    end
  end
end

Then('I should be on the accept placement request page') do
  expect(page.current_path).to eq path_for 'accept placement request',
    placement_request: @placement_request
end
