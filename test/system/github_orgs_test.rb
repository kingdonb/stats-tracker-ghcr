require "application_system_test_case"

class GithubOrgsTest < ApplicationSystemTestCase
  setup do
    @github_org = github_orgs(:one)
  end

  test "visiting the index" do
    visit github_orgs_url
    assert_selector "h1", text: "Github orgs"
  end

  test "should create github org" do
    visit github_orgs_url
    click_on "New github org"

    fill_in "Name", with: @github_org.name
    click_on "Create Github org"

    assert_text "Github org was successfully created"
    click_on "Back"
  end

  test "should update Github org" do
    visit github_org_url(@github_org)
    click_on "Edit this github org", match: :first

    fill_in "Name", with: @github_org.name
    click_on "Update Github org"

    assert_text "Github org was successfully updated"
    click_on "Back"
  end

  test "should destroy Github org" do
    visit github_org_url(@github_org)
    click_on "Destroy this github org", match: :first

    assert_text "Github org was successfully destroyed"
  end
end
