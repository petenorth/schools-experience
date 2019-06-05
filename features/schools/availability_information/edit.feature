Feature: Editing availability info
    So I can give candidates guidance when they are applying
    As a school administrator
    I want to be able to set my availability information text

    Background:
        Given I am logged in as a DfE user
        And my school is set to use 'flexible' dates

    Scenario: Page title
        Given I am on the 'availability information' page
        Then the page title should be 'Describe your school experience availability'

    Scenario: Breadcrumbs
        Given I am on the 'availability information' page
        Then I should see the following breadcrumbs:
            | Text                                         | Link     |
            | Some school                                  | /schools |
            | Describe your school experience availability | None     |

    Scenario: Page contents
        Given I am on the 'availability information' page
        Then there should be a 'Describe your school experience availability' text area
        And the submit button should contain text 'Continue'

    Scenario: Submitting the form
        Given I am on the 'availability information' page
        When I enter 'Every third Tuesday' into the 'Describe your school experience availability' text area
        And I submit the form
        Then I should be on the 'schools dashboard' page
        And my school's availabiltiy info should have been updated