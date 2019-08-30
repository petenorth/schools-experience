Feature: Configuring a placement date
    So I can manage placement dates
    As a school administrator
    I want to be able to specify details about the dates we offer

  Background:
      Given I am logged in as a DfE user
      And my school is fully-onboarded
      And I have entered a placement date

  Scenario: Page title
    Then the page's main heading should be the date I just entered

  @javascript
  Scenario: Select no max number of bookings
    When I choose 'No' from the "Is there a maximum number of bookings you’ll accept for this date?" radio buttons
    Then there is no 'Enter maximum number of bookings' text area

  @javascript
  Scenario: Select max number of bookings
    When I choose 'Yes' from the "Is there a maximum number of bookings you’ll accept for this date?" radio buttons
    Then there should be a 'Enter maximum number of bookings.' number field

  Scenario: Date is not subject specific
    Given I choose 'No' from the "Is there a maximum number of bookings you’ll accept for this date?" radio buttons
    And I choose 'Yes' from the "Is this date available for all the subjects you offer?" radio buttons
    When I submit the form
    Then I should be on the 'placement dates' page
    And my newly-created placement date should be listed

  Scenario: Date is subject specific
    Given I choose 'No' from the "Is there a maximum number of bookings you’ll accept for this date?" radio buttons
    And I choose 'No' from the "Is this date available for all the subjects you offer?" radio buttons
    When I submit the form
    Then I should be on the new subject selection page for this date