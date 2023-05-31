require "application_system_test_case"

class RepositoriesTest < ApplicationSystemTestCase
  setup do
    @repository = repositories(:one)
  end

  test "visiting the index" do
    visit repositories_url
    assert_selector "h1", text: "Repositories"
  end

  test "should create repository" do
    visit repositories_url
    click_on "New repository"

    fill_in "Github org", with: @repository.github_org_id
    fill_in "Name", with: @repository.name
    click_on "Create Repository"

    assert_text "Repository was successfully created"
    click_on "Back"
  end

  test "should update Repository" do
    visit repository_url(@repository)
    click_on "Edit this repository", match: :first

    fill_in "Github org", with: @repository.github_org_id
    fill_in "Name", with: @repository.name
    click_on "Update Repository"

    assert_text "Repository was successfully updated"
    click_on "Back"
  end

  test "should destroy Repository" do
    visit repository_url(@repository)
    click_on "Destroy this repository", match: :first

    assert_text "Repository was successfully destroyed"
  end
end
