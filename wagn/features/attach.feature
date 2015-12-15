@javascript
Feature: File Upload
  I want to be able to upload files and images.

  Background:
    Given I am signed in as Joe Admin
    And I wait until ajax response done

  Scenario: Uploading a file
    When I go to new File
    And I upload the file "file.txt"
    And I wait until ajax response done
    Then I should see "file.txt 9 Bytes"
    When I press "Delete"
    Then I should see "Add file..."
    When I upload the file "file.txt"
    And I wait until ajax response done
    And I fill in "card_name" with "a test file"
    And I press "Submit"
    Then I should see "Download a test file"

  Scenario: Uploading and changing an image
    When I go to new Image
    And I upload the image "image.png"
    And I wait until ajax response done
    Then I should see "image.png 34.3 KB"
    And I fill in "card_name" with "a test image"
    And I press "Submit"
    Then I should see an image of size "large" and type "png"
    And I edit "a test image"
    And I upload the image "image2.jpg"
    And I wait until ajax response done
    Then I should see "image2.jpg 69.8 KB"
    And I press "Submit"
    Then I should see an image of size "large" and type "jpg"
    And I wait until ajax response done

  Scenario: Changing a mod image
    When I edit "*logo"
    And I upload the image "image2.jpg"
    And I wait until ajax response done
    Then I should see "image2.jpg 69.8 KB"
    And I press "Submit"
    And I wait until ajax response done
    Then I should see a non-mod image of size "large" and type "jpg"

  Scenario: uploading a file as a field in a form
    When I go to  "/new Cardtype"
    And I fill in "card_name" with "complicated_card"
    And I press "Submit"
    And I create HTML card "complicated card+*type+*structure" with content "{{+image}}{{+description}}"
    And I go to "/new complicated_card"
    And I fill in "card_name" with "Vignesh has a complicated relationship"
    And I wait until ajax response done
    And I upload the image "image.png"
    And I wait until ajax response done
    Then I should see "image.png 34.3 KB"
    And I press "Submit"
    Then I should see an image of size "medium" and type "png"
    And I wait until ajax response done

  Scenario: updating a file as a field in a form
    When I go to  "/new Cardtype"
    And I fill in "card_name" with "complicated_card"
    And I press "Submit"
    And I create HTML card "complicated card+*type+*structure" with content "{{+image}}{{+description}}"
    And I go to "/new complicated_card"
    And I fill in "card_name" with "Vignesh has a complicated relationship"
    And I wait until ajax response done
    And I upload the image "image.png"
    And I wait until ajax response done
    And I press "Submit"
    And I edit "Vignesh has a complicated relationship"
    And I upload the image "image2.jpg"
    And I wait until ajax response done
    Then I should see "image2.jpg 69.8 KB"
    And I press "Submit"
    Then I should see an image of size "medium" and type "jpg"
    And I wait until ajax response done

  Scenario: submit a form without updating a file
    When I go to  "/new Cardtype"
    And I fill in "card_name" with "complicated_card"
    And I press "Submit"
    And I create HTML card "complicated card+*type+*structure" with content "{{+image}}{{+description}}"
    And I go to "/new complicated_card"
    And I fill in "card_name" with "Vignesh has a complicated relationship"
    And I wait until ajax response done
    And I upload the image "image.png"
    And I wait until ajax response done
    And I press "Submit"
    And I edit "Vignesh has a complicated relationship"
    And I press "Submit"
    And I wait until ajax response done
    Then within ".card-body" I should see an image of size "medium" and type "png"
    And I wait until ajax response done


