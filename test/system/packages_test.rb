require "application_system_test_case"

class PackagesTest < ApplicationSystemTestCase
  setup do
    @package = packages(:one)
  end

  test "visiting the index" do
    visit packages_url
    assert_selector "h1", text: "Packages"
  end

  test "should create package" do
    visit packages_url
    click_on "New package"

    fill_in "Download count", with: @package.download_count
    fill_in "Name", with: @package.name
    fill_in "Repository", with: @package.repository_id
    click_on "Create Package"

    assert_text "Package was successfully created"
    click_on "Back"
  end

  test "should update Package" do
    visit package_url(@package)
    click_on "Edit this package", match: :first

    fill_in "Download count", with: @package.download_count
    fill_in "Name", with: @package.name
    fill_in "Repository", with: @package.repository_id
    click_on "Update Package"

    assert_text "Package was successfully updated"
    click_on "Back"
  end

  test "should destroy Package" do
    visit package_url(@package)
    click_on "Destroy this package", match: :first

    assert_text "Package was successfully destroyed"
  end
end
