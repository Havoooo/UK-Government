Feature: News articles
  Background:
    Given I am an GDS editor
    And I have the "Preview design system" permission

  Scenario: Create a news article of type 'News story'
    When I draft a valid news article of type "News story" with title "You will never guess"
    Then the news article "You will never guess" should have been created

  Scenario: Create a news article of type 'Press release'
    When I draft a valid news article of type "Press release" with title "This is serious"
    Then the news article "This is serious" should have been created

  Scenario: Create a news article of type 'Government response'
    When I draft a valid news article of type "Government response" with title "Yes we can"
    Then the news article "Yes we can" should have been created

  Scenario: Create a news article of type 'World news story'
    When I draft a valid news article of type "World news story" with title "A thing happened in X"
    Then the news article "A thing happened in X" should have been created

  Scenario: Create a news article of type 'World news story', then changing its locale from en
    When I draft a valid news article of type "World news story" with title "A thing happened in X"
    Then the news article "A thing happened in X" should have been created
    And when I publish the article
    And I subsequently change the primary locale
    Then there should exist only one translation

  Scenario: Create a News article of type 'world news story' in a non-English language
    Given an international delegation "UK and the World Government" exists with a translation for the locale "Français"
    When I draft a French-only "World news story" news article associated with "UK and the World Government"
    Then I should see the news article listed in admin with an indication that it is in French
    And when I publish the article
    Then I should only see the news article on the French version of the public "UK and the World Government" location page
