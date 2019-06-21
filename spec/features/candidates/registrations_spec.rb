require 'rails_helper'

feature 'Candidate Registrations', type: :feature do
  include_context 'Stubbed candidates school'

  let! :today do
    Date.today
  end

  let! :tomorrow do
    today + 1.day
  end

  let! :today_in_words do
    today.strftime '%d %B %Y'
  end

  let! :tomorrow_in_words do
    tomorrow.strftime '%d %B %Y'
  end

  let :uuid do
    'some-uuid'
  end

  let :registration_session do
    FactoryBot.build :registration_session, current_time: today
  end

  before do
    allow(Candidates::School).to receive(:find) { school }

    allow(SecureRandom).to receive(:urlsafe_base64) { uuid }

    allow(NotifyEmail::CandidateMagicLink).to receive :new do
      double NotifyEmail::CandidateMagicLink, despatch!: true
    end

    allow(NotifyEmail::SchoolRequestConfirmation).to receive :new do
      double NotifyEmail::SchoolRequestConfirmation, despatch!: true
    end

    allow(NotifyEmail::CandidateRequestConfirmation).to receive :new do
      double NotifyEmail::CandidateRequestConfirmation, despatch!: true
    end
  end

  feature 'Candidate Registration' do
    context 'for unknown Candidate' do
      let(:email_address) { 'unknown@example.com' }

      scenario "completing the Journey" do
        complete_personal_information_step
        complete_contact_information_step
        complete_subject_preference_step
        complete_placement_preference_step
        complete_background_step
        complete_application_preview_step
        complete_email_confirmation_step
        view_request_acknowledgement_step
      end
    end

    context 'for known Candidate' do
      let(:token) { create(:candidate_session_token) }
      let(:email_address) { 'test@example.com' }

      before do
        allow_any_instance_of(Candidates::Registrations::PersonalInformation).to \
          receive(:create_signin_token).and_return(token.token)
      end

      scenario "completing the Journey" do
        complete_personal_information_step
        complete_sign_in_step(token.token)
        complete_contact_information_step
        complete_subject_preference_step
        complete_placement_preference_step
        complete_background_step
        complete_application_preview_step
        complete_email_confirmation_step
        view_request_acknowledgement_step
      end
    end
  end

  def complete_personal_information_step
    # Begin wizard journey
    visit "/candidates/schools/#{school_urn}/registrations/personal_information/new"
    expect(page).to have_text 'Enter your personal details'

    # Submit personal information form with errors
    fill_in 'First name', with: 'testy'
    fill_in 'Last name', with: 'mctest'
    click_button 'Continue'
    expect(page).to have_text 'There is a problem'

    # Submit personal information form successfully
    fill_in 'First name', with: 'testy'
    fill_in 'Last name', with: 'mctest'
    fill_in 'Email address', with: email_address
    click_button 'Continue'
  end

  def complete_sign_in_step(token)
    expect(page.current_path).to eq \
      "/candidates/schools/#{school_urn}/registrations/sign_ins"
    expect(page).to have_text 'Verify your email address'

    # Follow the link from email
    visit "/candidates/schools/#{school_urn}/registrations/sign_ins/#{token}"
  end

  def complete_contact_information_step
    expect(page.current_path).to eq \
      "/candidates/schools/#{school_urn}/registrations/contact_information/new"

    # Submit contact information form with errors
    fill_in 'Building', with: 'Test house'
    click_button 'Continue'
    expect(page).to have_text 'There is a problem'

    # Submit contact information form successfully
    fill_in 'Building', with: 'Test house'
    fill_in 'Street', with: 'Test street'
    fill_in 'Town or city', with: 'Test Town'
    fill_in 'County', with: 'Testshire'
    fill_in 'Postcode', with: 'TE57 1NG'
    fill_in 'UK telephone number', with: '01234567890'
    click_button 'Continue'
  end

  def complete_subject_preference_step
    expect(page.current_path).to eq \
      "/candidates/schools/#{school_urn}/registrations/subject_preference/new"

    # Submit registrations/subject_preference form with errors
    choose 'Graduate or postgraduate'
    select 'Physics', from: 'If you have or are studying for a degree, tell us about your degree subject'
    choose "I’m very sure and think I’ll apply"
    select 'Maths', from: 'Second choice'
    click_button 'Continue'
    expect(page).to have_text "There is a problem"

    # Submit registrations/subject_preference form successfully
    choose 'Graduate or postgraduate'
    select 'Physics', from: 'If you have or are studying for a degree, tell us about your degree subject'
    choose "I’m very sure and think I’ll apply"
    select 'Physics', from: 'First choice'
    click_button 'Continue'
  end

  def complete_placement_preference_step
    expect(page.current_path).to eq \
      "/candidates/schools/#{school_urn}/registrations/placement_preference/new"

    # Submit registrations/placement_preference form with errors
    fill_in 'What do you want to get out of your school experience?', with: 'I enjoy teaching'
    click_button 'Continue'
    expect(page).to have_text 'There is a problem'

    # Submit registrations/placement_preference form successfully
    fill_in 'Is there anything schools need to know about your availability for school experience?', with: 'Only free from Epiphany to Whitsunday'
    fill_in 'What do you want to get out of your school experience?', with: 'I enjoy teaching'
    click_button 'Continue'
  end

  def complete_background_step
    expect(page.current_path).to eq \
      "/candidates/schools/#{school_urn}/registrations/background_check/new"

    # Submit registrations/background_check form with errors
    click_button 'Continue'
    expect(page).to have_text 'There is a problem'

    # Submit registrations/background_check form successfully
    choose 'Yes'
    click_button 'Continue'
  end

  def complete_application_preview_step
    expect(page.current_path).to eq \
      "/candidates/schools/#{school_urn}/registrations/application_preview"

    # Expect preview to match the data we successfully submited
    expect(page).to have_text 'Full name testy mctest'
    expect(page).to have_text \
      'Address Test house, Test street, Test Town, Testshire, TE57 1NG'
    expect(page).to have_text 'UK telephone number 01234567890'
    expect(page).to have_text "Email address #{email_address}"
    expect(page).to have_text "School or college #{school.name}"
    expect(page).to have_text 'Experience availability Only free from Epiphany to Whitsunday'
    expect(page).to have_text "Experience outcome I enjoy teaching"
    expect(page).to have_text "Degree stage Graduate or postgraduate"
    expect(page).to have_text "Degree subject Physics"
    expect(page).to have_text "I’m very sure and think I’ll apply"
    expect(page).to have_text "Teaching subject - first choice Physics"
    expect(page).to have_text "Teaching subject - second choice Maths"
    expect(page).to have_text "DBS certificate Yes"

    # Submit email confirmation form with errors
    click_button 'Accept and send'
    expect(page).to have_text 'You need to confirm your details are correct and accept our privacy policy to continue'
    expect(page).not_to have_text \
      "Click the link in the email we’ve sent to the following email address to verify your request for school experience at Test School:\ntest@example.com"

    # Submit email confirmation form successfully
    check \
      "By checking this box and sending this request you’re confirming, to the best of your knowledge, the details you’re providing are correct and you accept our privacy policy"
    click_button 'Accept and send'
  end

  def complete_email_confirmation_step
    expect(page).to have_text \
      "Click the link in the email we’ve sent to the following email address to verify your request for school experience at Test School:\n#{email_address}"

    # Click email confirmation link
    visit "/candidates/confirm/#{uuid}"
  end

  def view_request_acknowledgement_step
    expect(page).to have_text \
      "Your request for school experience will be forwarded to Test School."
  end
end
