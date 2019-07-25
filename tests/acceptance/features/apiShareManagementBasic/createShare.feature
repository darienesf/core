@api @TestAlsoOnExternalUserBackend
Feature: sharing

  Background:
    Given using old DAV path
    And user "user0" has been created with default attributes and skeleton files

  @smokeTest
  @skipOnEncryptionType:user-keys @issue-32322
  Scenario Outline: Creating a share of a file with a user, the default permissions are read(1)+update(2)+can-share(16)
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    When user "user0" shares file "welcome.txt" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | user1             |
      | file_target | /welcome.txt      |
      | path        | /welcome.txt      |
      | permissions | share,read,update |
      | uid_owner   | user0             |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Creating a share of a file with a user and asking for various permission combinations
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    When user "user0" shares file "welcome.txt" with user "user1" with permissions <requested_permissions> using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | user1                 |
      | file_target | /welcome.txt          |
      | path        | /welcome.txt          |
      | permissions | <granted_permissions> |
      | uid_owner   | user0                 |
    Examples:
      | ocs_api_version | requested_permissions | granted_permissions | ocs_status_code |
      # Ask for full permissions. You get share plus read plus update. create and delete do not apply to shares of a file
      | 1               | 31                    | 19                  | 100             |
      | 2               | 31                    | 19                  | 200             |
      # Ask for share (16), create and delete. You get share plus read
      | 1               | 28                    | 17                  | 100             |
      | 2               | 28                    | 17                  | 200             |
      # Ask for read, update, create, delete. You get read plus update.
      | 1               | 15                    | 3                   | 100             |
      | 2               | 15                    | 3                   | 200             |
      # Ask for create and delete. You get just read.
      | 1               | 12                    | 1                   | 100             |
      | 2               | 12                    | 1                   | 200             |
      # Ask for just update. You get read plus update.
      | 1               | 2                     | 3                   | 100             |
      | 2               | 2                     | 3                   | 200             |

  Scenario Outline: Creating a share of a folder with a user, the default permissions are all permissions(31)
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    When user "user0" shares folder "/FOLDER" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | user1   |
      | file_target | /FOLDER |
      | path        | /FOLDER |
      | permissions | all     |
      | uid_owner   | user0   |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Creating a share of a file with a group, the default permissions are read(1)+update(2)+can-share(16)
    Given using OCS API version "<ocs_api_version>"
    And group "grp1" has been created
    When user "user0" shares file "/welcome.txt" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | grp1              |
      | file_target | /welcome.txt      |
      | path        | /welcome.txt      |
      | permissions | share,read,update |
      | uid_owner   | user0             |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Creating a share of a folder with a group, the default permissions are all permissions(31)
    Given using OCS API version "<ocs_api_version>"
    And group "grp1" has been created
    When user "user0" shares folder "/FOLDER" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | grp1    |
      | file_target | /FOLDER |
      | path        | /FOLDER |
      | permissions | all     |
      | uid_owner   | user0   |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Creating a new share with user who already received a share through their group
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user0" has shared file "welcome.txt" with group "grp1"
    When user "user0" shares file "/welcome.txt" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | user1             |
      | file_target | /welcome.txt      |
      | path        | /welcome.txt      |
      | permissions | share,read,update |
      | uid_owner   | user0             |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Creating a new public link share of a file, the default permissions are read (1)
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path | welcome.txt |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | item_type              | file         |
      | mimetype               | text/plain   |
      | file_target            | /welcome.txt |
      | path                   | /welcome.txt |
      | permissions            | read         |
      | share_type             | public_link  |
      | displayname_file_owner | User Zero    |
      | displayname_owner      | User Zero    |
      | uid_file_owner         | user0        |
      | uid_owner              | user0        |
      | name                   |              |
    And the last public shared file should be able to be downloaded without a password
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @smokeTest @public_link_share-feature-required
  Scenario Outline: Creating a new public link share of a file with password
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path     | welcome.txt |
      | password | %public%    |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | item_type              | file         |
      | mimetype               | text/plain   |
      | file_target            | /welcome.txt |
      | path                   | /welcome.txt |
      | permissions            | read         |
      | share_type             | public_link  |
      | displayname_file_owner | User Zero    |
      | displayname_owner      | User Zero    |
      | uid_file_owner         | user0        |
      | uid_owner              | user0        |
      | name                   |              |
    And the last public shared file should be able to be downloaded with password "%public%"
    But the last public shared file should not be able to be downloaded with password "%regular%"
    And the last public shared file should not be able to be downloaded without a password
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Trying to create a new public link share of a file with edit permissions results in a read-only share
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path        | welcome.txt |
      | permissions | all         |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | item_type              | file         |
      | mimetype               | text/plain   |
      | file_target            | /welcome.txt |
      | path                   | /welcome.txt |
      | permissions            | read         |
      | share_type             | public_link  |
      | displayname_file_owner | User Zero    |
      | displayname_owner      | User Zero    |
      | uid_file_owner         | user0        |
      | uid_owner              | user0        |
      | name                   |              |
    And the last public shared file should be able to be downloaded without a password
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Creating a new public link share of a folder, the default permissions are read (1) and can be accessed with no password or any password
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path     | PARENT   |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | item_type              | folder               |
      | mimetype               | httpd/unix-directory |
      | file_target            | /PARENT              |
      | path                   | /PARENT              |
      | permissions            | read                 |
      | share_type             | public_link          |
      | displayname_file_owner | User Zero            |
      | displayname_owner      | User Zero            |
      | uid_file_owner         | user0                |
      | uid_owner              | user0                |
      | name                   |                      |
    And the public should be able to download the range "bytes=1-7" of file "/parent.txt" from inside the last public shared folder and the content should be "wnCloud"
    And the public should be able to download the range "bytes=1-7" of file "/parent.txt" from inside the last public shared folder with password "%regular%" and the content should be "wnCloud"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Creating a new public link share of a folder, with a password
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path     | PARENT   |
      | password | %public% |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | item_type              | folder               |
      | mimetype               | httpd/unix-directory |
      | file_target            | /PARENT              |
      | path                   | /PARENT              |
      | permissions            | read                 |
      | share_type             | public_link          |
      | displayname_file_owner | User Zero            |
      | displayname_owner      | User Zero            |
      | uid_file_owner         | user0                |
      | uid_owner              | user0                |
      | name                   |                      |
    And the public should be able to download the range "bytes=1-7" of file "/parent.txt" from inside the last public shared folder with password "%public%" and the content should be "wnCloud"
    But the public should not be able to download file "/parent.txt" from inside the last public shared folder without a password
    And the public should not be able to download file "/parent.txt" from inside the last public shared folder with password "%regular%"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Getting the share information of public link share from the OCS API does not expose sensitive information
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path     | welcome.txt   |
      | password | %public%      |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | file_target            | /welcome.txt   |
      | path                   | /welcome.txt   |
      | item_type              | file           |
      | share_type             | public_link    |
      | permissions            | read           |
      | uid_owner              | user0          |
      | share_with             | ***redacted*** |
      | share_with_displayname | ***redacted*** |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Getting the share information of passwordless public-links hides credential placeholders
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path     | welcome.txt   |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | file_target            | /welcome.txt   |
      | path                   | /welcome.txt   |
      | item_type              | file           |
      | share_type             | public_link    |
      | permissions            | read           |
      | uid_owner              | user0          |
    And the fields of the last response should not include
      | share_with             | ANY_VALUE |
      | share_with_displayname | ANY_VALUE |

    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Creating a new share with a disabled user
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And user "user0" has been disabled
    When user "user0" shares file "welcome.txt" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "401"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 997             |

  @issue-32068
  Scenario: Creating a new share with a disabled user
    Given using OCS API version "2"
    And user "user1" has been created with default attributes and without skeleton files
    And user "user0" has been disabled
    When user "user0" shares file "welcome.txt" with user "user1" using the sharing API
    Then the OCS status code should be "997"
    #And the OCS status code should be "401"
    And the HTTP status code should be "401"

  @public_link_share-feature-required
  Scenario Outline: Creating a link share with no specified permissions defaults to read permissions when public upload disabled globally
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_allow_public_upload" of app "core" has been set to "no"
    And user "user0" has created folder "/afolder"
    When user "user0" creates a public link share using the sharing API with settings
      | path | /afolder |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | id          | A_NUMBER    |
      | share_type  | public_link |
      | permissions | read        |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Creating a link share with edit permissions keeps it
    Given using OCS API version "<ocs_api_version>"
    And user "user0" has created folder "/afolder"
    When user "user0" creates a public link share using the sharing API with settings
      | path        | /afolder                  |
      | permissions | read,update,create,delete |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | id          | A_NUMBER                  |
      | share_type  | public_link               |
      | permissions | read,update,create,delete |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Creating a link share with upload permissions keeps it
    Given using OCS API version "<ocs_api_version>"
    And user "user0" has created folder "/afolder"
    When user "user0" creates a public link share using the sharing API with settings
      | path        | /afolder    |
      | permissions | read,create |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | id          | A_NUMBER    |
      | share_type  | public_link |
      | permissions | read,create |
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Share of folder and sub-folder to same user - core#20645
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and skeleton files
    And group "grp4" has been created
    # Note: in the user_ldap test environment user1 is in grp4
    And user "user1" has been added to group "grp4"
    When user "user0" shares folder "/PARENT" with user "user1" using the sharing API
    And user "user0" shares folder "/PARENT/CHILD" with group "grp4" using the sharing API
    Then user "user1" should see the following elements
      | /FOLDER/                 |
      | /PARENT/                 |
      | /PARENT/parent.txt       |
      | /PARENT%20(2)/           |
      | /PARENT%20(2)/parent.txt |
      | /CHILD/                  |
      | /CHILD/child.txt         |
    And the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @smokeTest
  Scenario Outline: Share of folder to a group
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and skeleton files:
      | username |
      | user1    |
      | user2    |
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 and user2 are in grp1
    And user "user1" has been added to group "grp1"
    And user "user2" has been added to group "grp1"
    When user "user0" shares folder "/PARENT" with group "grp1" using the sharing API
    Then user "user1" should see the following elements
      | /FOLDER/                 |
      | /PARENT/                 |
      | /PARENT/parent.txt       |
      | /PARENT%20(2)/           |
      | /PARENT%20(2)/parent.txt |
    And the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And user "user2" should see the following elements
      | /FOLDER/                 |
      | /PARENT/                 |
      | /PARENT/parent.txt       |
      | /PARENT%20(2)/           |
      | /PARENT%20(2)/parent.txt |
    And the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: Do not allow public sharing of the root
    Given using OCS API version "<ocs_api_version>"
    When user "user0" creates a public link share using the sharing API with settings
      | path | / |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 403             | 200              |
      | 2               | 403             | 403              |

  @public_link_share-feature-required
  Scenario: Only allow 1 link share per file/folder
    Given using OCS API version "1"
    And as user "user0"
    And the user has created a public link share with settings
      | path | welcome.txt |
    And the last share id has been remembered
    When the user creates a public link share using the sharing API with settings
      | path | welcome.txt |
    Then the share ids should match

  @smokeTest
  Scenario: unique target names for incoming shares
    Given using OCS API version "1"
    And these users have been created with default attributes and skeleton files:
      | username |
      | user1    |
      | user2    |
    And user "user0" has created folder "/foo"
    And user "user1" has created folder "/foo"
    When user "user0" shares folder "/foo" with user "user2" using the sharing API
    And user "user1" shares folder "/foo" with user "user2" using the sharing API
    Then user "user2" should see the following elements
      | /foo/       |
      | /foo%20(2)/ |

  Scenario Outline: sharing again an own file while belonging to a group
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user1" has shared file "welcome.txt" with group "grp1"
    And user "user1" has deleted the last share
    When user "user1" shares file "/welcome.txt" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: sharing subfolder when parent already shared
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And group "grp1" has been created
    And user "user0" has created folder "/test"
    And user "user0" has created folder "/test/sub"
    And user "user0" has shared folder "/test" with group "grp1"
    When user "user0" shares folder "/test/sub" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And as "user1" folder "/sub" should exist
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: sharing subfolder when parent already shared with group of sharer
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And user "user3" has been created with default attributes and without skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user1" has created folder "/test"
    And user "user1" has created folder "/test/sub"
    And user "user1" has shared folder "/test" with group "grp1"
    When user "user1" shares folder "/test/sub" with user "user3" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And as "user3" folder "/sub" should exist
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: sharing subfolder of already shared folder, GET result is correct
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
      | user3    |
      | user4    |
    And user "user0" has created folder "/folder1"
    And user "user0" has shared folder "/folder1" with user "user1"
    And user "user0" has shared folder "/folder1" with user "user2"
    And user "user0" has created folder "/folder1/folder2"
    And user "user0" has shared folder "/folder1/folder2" with user "user3"
    And user "user0" has shared folder "/folder1/folder2" with user "user4"
    And as user "user0"
    When the user sends HTTP method "GET" to OCS API endpoint "/apps/files_sharing/api/v1/shares"
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the response should contain 4 entries
    And folder "/folder1" should be included as path in the response
    And folder "/folder1/folder2" should be included as path in the response
    And the user sends HTTP method "GET" to OCS API endpoint "/apps/files_sharing/api/v1/shares?path=/folder1/folder2"
    And the response should contain 2 entries
    And folder "/folder1" should not be included as path in the response
    And folder "/folder1/folder2" should be included as path in the response
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: Cannot create a share of a file or folder with invalid permissions
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    When user "user0" creates a share using the sharing API with settings
      | path        | <item>        |
      | shareWith   | user1         |
      | shareType   | user          |
      | permissions | <permissions> |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user1" entry "<item>" should not exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code | item          | permissions |
      | 1               | 400             | 200              | textfile0.txt | 0           |
      | 2               | 400             | 400              | textfile0.txt | 0           |
      | 1               | 400             | 200              | PARENT        | 0           |
      | 2               | 400             | 400              | PARENT        | 0           |
      | 1               | 404             | 200              | textfile0.txt | 32          |
      | 2               | 404             | 404              | textfile0.txt | 32          |
      | 1               | 404             | 200              | PARENT        | 32          |
      | 2               | 404             | 404              | PARENT        | 32          |

  @issue-12345
  Scenario Outline: Cannot create a share of a file with only create permission
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    When user "user0" creates a share using the sharing API with settings
      | path        | textfile0.txt |
      | shareWith   | user1         |
      | shareType   | user          |
      | permissions | <permissions> |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    # delete the following step when the issue is fixed. The share should not be created at all.
    And the fields of the last response should include
      | share_with  | user1          |
      | share_type  | user           |
      | file_target | /textfile0.txt |
      | path        | /textfile0.txt |
      | permissions | 0              |
    And as "user1" entry "textfile0.txt" should not exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code | permissions |
      | 1               | 100             | 200              | create      |
      | 2               | 200             | 200              | create      |
      #| 1               | 400             | 200              | create      |
      #| 2               | 400             | 400              | create      |

  @issue-12345
  Scenario Outline: Cannot create a share of a file with only (create,)delete permission
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    When user "user0" creates a share using the sharing API with settings
      | path        | textfile0.txt |
      | shareWith   | user1         |
      | shareType   | user          |
      | permissions | <permissions> |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    # delete the following step when the issue is fixed. The share should not be created at all.
    And the fields of the last response should include
      | share_with  | user1          |
      | share_type  | user           |
      | file_target | /textfile0.txt |
      | path        | /textfile0.txt |
      | permissions | 1              |
    # because the share got created wrongly with read permission, the file exists for the sharee
    And as "user1" entry "textfile0.txt" should exist
    #And as "user1" entry "textfile0.txt" should not exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code | permissions   |
      | 1               | 100             | 200              | delete        |
      | 2               | 200             | 200              | delete        |
      | 1               | 100             | 200              | create,delete |
      | 2               | 200             | 200              | create,delete |
      #| 1               | 404             | 200              | delete        |
      #| 2               | 404             | 404              | delete        |
      #| 1               | 404             | 200              | create,delete |
      #| 2               | 404             | 404              | create,delete |

  Scenario Outline: user who is excluded from sharing tries to share a file with another user
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and skeleton files
    And group "grp1" has been created
    # Note: in user_ldap, user1 is already in grp1
    And user "user1" has been added to group "grp1"
    And parameter "shareapi_exclude_groups" of app "core" has been set to "yes"
    And parameter "shareapi_exclude_groups_list" of app "core" has been set to '["grp1"]'
    And user "user1" has moved file "welcome.txt" to "fileToShare.txt"
    When user "user1" shares file "fileToShare.txt" with user "user0" using the sharing API
    Then the OCS status code should be "403"
    And the HTTP status code should be "<http_status_code>"
    And as "user0" file "fileToShare.txt" should not exist
    Examples:
      | ocs_api_version | http_status_code |
      | 1               | 200              |
      | 2               | 403              |

  Scenario Outline: user who is excluded from sharing tries to share a file with a group
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and skeleton files
    And user "user3" has been created with default attributes and without skeleton files
    And group "grp1" has been created
    And group "grp2" has been created
    # Note: in user_ldap, user1 is already in grp1, user3 is already in grp2
    And user "user1" has been added to group "grp1"
    And user "user3" has been added to group "grp2"
    And parameter "shareapi_exclude_groups" of app "core" has been set to "yes"
    And parameter "shareapi_exclude_groups_list" of app "core" has been set to '["grp1"]'
    And user "user1" has moved file "welcome.txt" to "fileToShare.txt"
    When user "user1" shares file "fileToShare.txt" with group "grp2" using the sharing API
    Then the OCS status code should be "403"
    And the HTTP status code should be "<http_status_code>"
    And as "user3" file "fileToShare.txt" should not exist
    Examples:
      | ocs_api_version | http_status_code |
      | 1               | 200              |
      | 2               | 403              |

  Scenario Outline: user who is excluded from sharing tries to share a folder with another user
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And group "grp1" has been created
    # Note: in user_ldap, user1 is already in grp1
    And user "user1" has been added to group "grp1"
    And parameter "shareapi_exclude_groups" of app "core" has been set to "yes"
    And parameter "shareapi_exclude_groups_list" of app "core" has been set to '["grp1"]'
    And user "user1" has created folder "folderToShare"
    When user "user1" shares folder "folderToShare" with user "user0" using the sharing API
    Then the OCS status code should be "403"
    And the HTTP status code should be "<http_status_code>"
    And as "user0" folder "folderToShare" should not exist
    Examples:
      | ocs_api_version | http_status_code |
      | 1               | 200              |
      | 2               | 403              |

  Scenario Outline: user who is excluded from sharing tries to share a folder with a group
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And user "user3" has been created with default attributes and without skeleton files
    And group "grp1" has been created
    And group "grp2" has been created
    # Note: in user_ldap, user1 is already in grp1, user3 is already in grp2
    And user "user1" has been added to group "grp1"
    And user "user3" has been added to group "grp2"
    And parameter "shareapi_exclude_groups" of app "core" has been set to "yes"
    And parameter "shareapi_exclude_groups_list" of app "core" has been set to '["grp1"]'
    And user "user1" has created folder "folderToShare"
    When user "user1" shares folder "folderToShare" with group "grp2" using the sharing API
    Then the OCS status code should be "403"
    And the HTTP status code should be "<http_status_code>"
    And as "user2" folder "folderToShare" should not exist
    Examples:
      | ocs_api_version | http_status_code |
      | 1               | 200              |
      | 2               | 403              |

  Scenario Outline: user shares a file with file name longer than 64 chars to another user
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And user "user0" has moved file "welcome.txt" to "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt"
    When user "user0" shares file "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And as "user1" file "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt" should exist
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: user shares a file with file name longer than 64 chars to a group
    Given using OCS API version "<ocs_api_version>"
    And group "grp1" has been created
    And user "user1" has been created with default attributes and without skeleton files
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user0" has moved file "welcome.txt" to "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt"
    When user "user0" shares file "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And as "user1" file "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt" should exist
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: user shares a folder with folder name longer than 64 chars to another user
    Given using OCS API version "<ocs_api_version>"
    And user "user1" has been created with default attributes and without skeleton files
    And user "user0" has created folder "/aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog"
    And user "user0" has moved file "welcome.txt" to "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog/welcome.txt"
    When user "user0" shares folder "/aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog" with user "user1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the downloaded content when downloading file "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog/welcome.txt" for user "user1" with range "bytes=1-6" should be "elcome"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: user shares a folder with folder name longer than 64 chars to a group
    Given using OCS API version "<ocs_api_version>"
    And group "grp1" has been created
    And user "user1" has been created with default attributes and without skeleton files
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user0" has created folder "/aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog"
    And user "user0" has moved file "welcome.txt" to "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog/welcome.txt"
    When user "user0" shares folder "/aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the downloaded content when downloading file "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog/welcome.txt" for user "user1" with range "bytes=1-6" should be "elcome"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: user creates a public link share of a file with file name longer than 64 chars
    Given using OCS API version "<ocs_api_version>"
    And user "user0" has moved file "welcome.txt" to "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt"
    When user "user0" creates a public link share using the sharing API with settings
      | path | /aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog.txt |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the last public shared file should be able to be downloaded without a password
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @public_link_share-feature-required
  Scenario Outline: user creates a public link share of a folder with folder name longer than 64 chars
    Given using OCS API version "<ocs_api_version>"
    And user "user0" has created folder "/aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog"
    And user "user0" has moved file "welcome.txt" to "aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog/welcome.txt"
    When user "user0" creates a public link share using the sharing API with settings
      | path | /aquickbrownfoxjumpsoveraverylazydogaquickbrownfoxjumpsoveralazydog |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    Then the public should be able to download the range "bytes=1-6" of file "/welcome.txt" from inside the last public shared folder and the content should be "elcome"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  @issue-35484
  Scenario: share with user when username contains capital letters
    Given these users have been created without skeleton files:
      | username |
      | user1    |
    And user "user0" has uploaded file with content "user0 file" to "/randomfile.txt"
    When user "user0" shares file "/randomfile.txt" with user "USER1" using the sharing API
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | USER1             |
      | file_target | /randomfile.txt   |
      | path        | /randomfile.txt   |
      | permissions | share,read,update |
      | uid_owner   | user0             |
    #And user "user1" should see the following elements
    #  | /randomfile.txt |
    #And the content of file "randomfile.txt" for user "user1" should be "user0 file"
    And user "user1" should not see the following elements
      | /randomfile.txt |

  Scenario: creating a new share with user of a group when username contains capital letters
    Given these users have been created without skeleton files:
      | username |
      | user1    |
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 is in grp1
    And user "USER1" has been added to group "grp1"
    And user "user0" has uploaded file with content "user0 file" to "/randomfile.txt"
    And user "user0" has shared file "randomfile.txt" with group "grp1"
    Then the OCS status code should be "100"
    And the HTTP status code should be "200"
    And user "user1" should see the following elements
      | /randomfile.txt |
    And the content of file "randomfile.txt" for user "user1" should be "user0 file"

  Scenario Outline: Share of folder to a group with emoji in the name
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and skeleton files:
      | username |
      | user1    |
      | user2    |
    And group "😀 😁" has been created
    # Note: in the user_ldap test environment user1 and user2 are already in this group
    And user "user1" has been added to group "😀 😁"
    And user "user2" has been added to group "😀 😁"
    When user "user0" shares folder "/PARENT" with group "😀 😁" using the sharing API
    Then user "user1" should see the following elements
      | /FOLDER/                 |
      | /PARENT/                 |
      | /PARENT/parent.txt       |
      | /PARENT%20(2)/           |
      | /PARENT%20(2)/parent.txt |
    And the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And user "user2" should see the following elements
      | /FOLDER/                 |
      | /PARENT/                 |
      | /PARENT/parent.txt       |
      | /PARENT%20(2)/           |
      | /PARENT%20(2)/parent.txt |
    And the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |

  Scenario Outline: multiple users share a file with the same name but different permissions to a user
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
      | user3    |
    And user "user2" has uploaded file with content "user2 file" to "/randomfile.txt"
    And user "user3" has uploaded file with content "user3 file" to "/randomfile.txt"
    When user "user2" shares file "randomfile.txt" with user "user1" with permissions "read" using the sharing API
    And user "user1" gets the info of the last share using the sharing API
    Then the fields of the last response should include
      | uid_owner   | user2           |
      | share_with  | user1           |
      | file_target | /randomfile.txt |
      | item_type   | file            |
      | permissions | read            |
    When user "user3" shares file "randomfile.txt" with user "user1" with permissions "update" using the sharing API
    And user "user1" gets the info of the last share using the sharing API
    Then the fields of the last response should include
      | uid_owner   | user3              |
      | share_with  | user1              |
      | file_target | /randomfile (2).txt|
      | item_type   | file               |
      | permissions | read,update        |
    # Here the last response contains permissions = 3 which is equivalent to permissons: read(1) + update(2)
    And the content of file "randomfile.txt" for user "user1" should be "user2 file"
    And the content of file "randomfile (2).txt" for user "user1" should be "user3 file"
    Examples:
      | ocs_api_version |
      | 1               |
      | 2               |

  Scenario Outline: multiple users share a folder with the same name to a user
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
      | user3    |
    And user "user2" has created folder "/zzzfolder"
    And user "user2" has created folder "zzzfolder/user2"
    And user "user3" has created folder "/zzzfolder"
    And user "user3" has created folder "zzzfolder/user3"
    When user "user2" shares folder "zzzfolder" with user "user1" with permissions "delete" using the sharing API
    And user "user1" gets the info of the last share using the sharing API
    Then the fields of the last response should include
      | uid_owner   | user2       |
      | share_with  | user1       |
      | file_target | /zzzfolder  |
      | item_type   | folder      |
      | permissions | read,delete |
    When user "user3" shares folder "zzzfolder" with user "user1" with permissions "share" using the sharing API
    And user "user1" gets the info of the last share using the sharing API
    Then the fields of the last response should include
      | uid_owner   | user3          |
      | share_with  | user1          |
      | file_target | /zzzfolder (2) |
      | item_type   | folder         |
      | permissions | share,read     |
    And as "user1" folder "zzzfolder/user2" should exist
    And as "user1" folder "zzzfolder (2)/user3" should exist
    Examples:
      | ocs_api_version |
      | 1               |
      | 2               |

  @skipOnEncryptionType:user-keys @encryption-issue-132
  Scenario Outline: share with a group and then add a user to that group
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
    And these groups have been created:
      | groupname |
      | grp1      |
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user0" has uploaded file with content "some content" to "lorem.txt"
    When user "user0" shares file "lorem.txt" with group "grp1" using the sharing API
    And the administrator adds user "user2" to group "grp1" using the provisioning API
    Then the content of file "lorem.txt" for user "user1" should be "some content"
    And the content of file "lorem.txt" for user "user2" should be "some content"
    Examples:
      | ocs_api_version |
      | 1               |
      | 2               |

  @skipOnEncryptionType:user-keys @encryption-issue-132
  Scenario Outline: share with a group and then add a user to that group that already has a file with the shared name
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
    And these groups have been created:
      | groupname |
      | grp1      |
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    And user "user0" has uploaded file with content "user0 content" to "lorem.txt"
    And user "user2" has uploaded file with content "user2 content" to "lorem.txt"
    When user "user0" shares file "lorem.txt" with group "grp1" using the sharing API
    And the administrator adds user "user2" to group "grp1" using the provisioning API
    Then the content of file "lorem.txt" for user "user1" should be "user0 content"
    And the content of file "lorem.txt" for user "user2" should be "user2 content"
    And the content of file "lorem (2).txt" for user "user2" should be "user0 content"
    Examples:
      | ocs_api_version |
      | 1               |
      | 2               |

  @skipOnLDAP @issue-ldap-250
  Scenario Outline: group names are case-sensitive, sharing with groups with different upper and lower case names
    Given using OCS API version "<ocs_api_version>"
    And group "<group_id1>" has been created
    And group "<group_id2>" has been created
    And group "<group_id3>" has been created
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
      | user3    |
    And user "user1" has been added to group "<group_id1>"
    And user "user2" has been added to group "<group_id2>"
    And user "user3" has been added to group "<group_id3>"
    When user "user0" shares file "textfile1.txt" with group "<group_id1>" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the content of file "textfile1.txt" for user "user1" should be "ownCloud test text file 1" plus end-of-line
    When user "user0" shares folder "textfile2.txt" with group "<group_id2>" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the content of file "textfile2.txt" for user "user2" should be "ownCloud test text file 2" plus end-of-line
    When user "user0" shares folder "textfile3.txt" with group "<group_id3>" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the content of file "textfile3.txt" for user "user3" should be "ownCloud test text file 3" plus end-of-line
    Examples:
      | ocs_api_version | group_id1           | group_id2            | group_id3            | ocs_status_code |
      | 1              | case-sensitive-group | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | 100             |
      | 1              | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | case-sensitive-group | 100             |
      | 1              | CASE-SENSITIVE-GROUP | case-sensitive-group | Case-Sensitive-Group | 100             |
      | 2              | case-sensitive-group | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | 200             |
      | 2              | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | case-sensitive-group | 200             |
      | 2              | CASE-SENSITIVE-GROUP | case-sensitive-group | Case-Sensitive-Group | 200             |

  @skipOnLDAP @issue-ldap-250
  Scenario Outline: group names are case-sensitive, sharing with non-existent groups with different upper and lower case names
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
    And group "<group_id1>" has been created
    And user "user1" has been added to group "<group_id1>"
    When user "user0" shares file "textfile1.txt" with group "<group_id1>" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | <group_id1>       |
      | file_target | /textfile1.txt    |
      | path        | /textfile1.txt    |
      | permissions | share,read,update |
      | uid_owner   | user0             |
    And the content of file "textfile1.txt" for user "user1" should be "ownCloud test text file 1" plus end-of-line
    When user "user0" shares file "textfile2.txt" with group "<group_id2>" using the sharing API
    Then the OCS status code should be "404"
    And the HTTP status code should be "<http_status_code>"
    When user "user0" shares file "textfile3.txt" with group "<group_id3>" using the sharing API
    Then the OCS status code should be "404"
    And the HTTP status code should be "<http_status_code>"
    Examples:
      |ocs_api_version | group_id1            | group_id2            | group_id3            | ocs_status_code | http_status_code |
      | 1              | case-sensitive-group | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | 100             | 200              |
      | 1              | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | case-sensitive-group | 100             | 200              |
      | 1              | CASE-SENSITIVE-GROUP | case-sensitive-group | Case-Sensitive-Group | 100             | 200              |
      | 2              | case-sensitive-group | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | 200             | 404              |
      | 2              | Case-Sensitive-Group | CASE-SENSITIVE-GROUP | case-sensitive-group | 200             | 404              |
      | 2              | CASE-SENSITIVE-GROUP | case-sensitive-group | Case-Sensitive-Group | 200             | 404              |

  @public_link_share-feature-required
  Scenario Outline: Create a public link with default expiration date set and max expiration date enforced
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_default_expire_date" of app "core" has been set to "yes"
    And parameter "shareapi_enforce_expire_date" of app "core" has been set to "yes"
    When user "user0" creates a public link share using the sharing API with settings
      | path | textfile0.txt |
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And the fields of the last response should include
      | file_target | /textfile0.txt |
      | path        | /textfile0.txt |
      | item_type   | file           |
      | share_type  | public_link    |
      | permissions | read           |
      | uid_owner   | user0          |
      | expiration  | +7 days        |
    When user "user0" gets the info of the last share using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And the fields of the last response should include
      | file_target | /textfile0.txt |
      | path        | /textfile0.txt |
      | item_type   | file           |
      | share_type  | public_link    |
      | permissions | read           |
      | uid_owner   | user0          |
      | expiration  | +7 days        |
    And the last public shared file should be able to be downloaded without a password
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 100             | 200              |
      | 2               | 200             | 200              |

  Scenario Outline: sharer should not be able to share a folder to a group which he/she is not member of when share with only member group is enabled
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_only_share_with_membership_groups" of app "core" has been set to "yes"
    And user "user1" has been created with default attributes and skeleton files
    And user "user3" has been created with default attributes and skeleton files
    And group "grp1" has been created
    And group "grp2" has been created
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    # Note: in the user_ldap test environment user3 is in grp2
    And user "user3" has been added to group "grp2"
    When user "user1" shares folder "/PARENT" with group "grp2" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user3" folder "/PARENT (2)" should not exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 403             | 200              |
      | 2               | 403             | 403              |

  Scenario Outline: sharer should be able to share a folder to a user who is not member of sharer group when share with only member group is enabled
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_only_share_with_membership_groups" of app "core" has been set to "yes"
    And user "user1" has been created with default attributes and skeleton files
    And user "user3" has been created with default attributes and skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 is in grp1, and user3 is not in grp1
    And user "user1" has been added to group "grp1"
    When user "user1" shares folder "/PARENT" with user "user3" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user3" folder "/PARENT (2)" should exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 100             | 200              |
      | 2               | 200             | 200              |

  Scenario Outline: sharer should be able to share a folder to a group which he/she is member of when share with only member group is enabled
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_only_share_with_membership_groups" of app "core" has been set to "yes"
    And user "user1" has been created with default attributes and skeleton files
    And user "user2" has been created with default attributes and skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 and user2 are in grp1
    And user "user1" has been added to group "grp1"
    And user "user2" has been added to group "grp1"
    When user "user1" shares folder "/PARENT" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user2" folder "/PARENT (2)" should exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 100             | 200              |
      | 2               | 200             | 200              |

  Scenario Outline: sharer should not be able to share a file to a group which he/she is not member of when share with only member group is enabled
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_only_share_with_membership_groups" of app "core" has been set to "yes"
    And user "user1" has been created with default attributes and skeleton files
    And user "user3" has been created with default attributes and skeleton files
    And group "grp1" has been created
    And group "grp2" has been created
    # Note: in the user_ldap test environment user1 is in grp1
    And user "user1" has been added to group "grp1"
    # Note: in the user_ldap test environment user3 is in grp2
    And user "user3" has been added to group "grp2"
    When user "user1" shares file "/textfile0.txt" with group "grp2" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user3" file "/textfile0 (2).txt" should not exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 403             | 200              |
      | 2               | 403             | 403              |

  Scenario Outline: sharer should be able to share a file to a group which he/she is member of when share with only member group is enabled
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_only_share_with_membership_groups" of app "core" has been set to "yes"
    And user "user1" has been created with default attributes and skeleton files
    And user "user2" has been created with default attributes and skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 and user2 are in grp1
    And user "user1" has been added to group "grp1"
    And user "user2" has been added to group "grp1"
    When user "user1" shares folder "/textfile0.txt" with group "grp1" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user2" file "/textfile0 (2).txt" should exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 100             | 200              |
      | 2               | 200             | 200              |

  Scenario Outline: sharer should be able to share a file to a user who is not a member of sharer group when share with only member group is enabled
    Given using OCS API version "<ocs_api_version>"
    And parameter "shareapi_only_share_with_membership_groups" of app "core" has been set to "yes"
    And user "user1" has been created with default attributes and skeleton files
    And user "user3" has been created with default attributes and skeleton files
    And group "grp1" has been created
    # Note: in the user_ldap test environment user1 is in grp1, and user3 is not in grp1
    And user "user1" has been added to group "grp1"
    When user "user1" shares folder "/textfile0.txt" with user "user3" using the sharing API
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "<http_status_code>"
    And as "user3" file "/textfile0 (2).txt" should exist
    Examples:
      | ocs_api_version | ocs_status_code | http_status_code |
      | 1               | 100             | 200              |
      | 2               | 200             | 200              |

  @skipOnLDAP
  # deleting an LDAP group is not relevant or possible using the provisioning API
  Scenario Outline: shares shared to deleted group should not be available
    Given using OCS API version "<ocs_api_version>"
    And these users have been created with default attributes and without skeleton files:
      | username |
      | user1    |
      | user2    |
    And group "grp1" has been created
    And user "user1" has been added to group "grp1"
    And user "user2" has been added to group "grp1"
    And user "user0" has shared file "/textfile0.txt" with group "grp1"
    And as user "user0"
    When the user sends HTTP method "GET" to OCS API endpoint "/apps/files_sharing/api/v1/shares"
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And the fields of the last response should include
      | share_with  | grp1                 |
      | file_target | /textfile0.txt       |
      | path        | /textfile0.txt       |
      | uid_owner   | user0                |
    And as "user1" file "/textfile0.txt" should exist
    And as "user2" file "/textfile0.txt" should exist
    When the administrator deletes group "grp1" using the provisioning API
    And as user "user0"
    When the user sends HTTP method "GET" to OCS API endpoint "/apps/files_sharing/api/v1/shares"
    Then the OCS status code should be "<ocs_status_code>"
    And the HTTP status code should be "200"
    And file "/textfile0.txt" should not be included as path in the response
    And as "user1" file "/textfile0.txt" should not exist
    And as "user2" file "/textfile0.txt" should not exist
    Examples:
      | ocs_api_version | ocs_status_code |
      | 1               | 100             |
      | 2               | 200             |
