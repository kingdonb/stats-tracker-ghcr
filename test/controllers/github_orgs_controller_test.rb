require "test_helper"

class GithubOrgsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @github_org = github_orgs(:one)
  end

  test "should get index" do
    get github_orgs_url
    assert_response :success
  end

  test "should get new" do
    get new_github_org_url
    assert_response :success
  end

  test "should create github_org" do
    assert_difference("GithubOrg.count") do
      post github_orgs_url, params: { github_org: { name: @github_org.name } }
    end

    assert_redirected_to github_org_url(GithubOrg.last)
  end

  test "should show github_org" do
    get github_org_url(@github_org)
    assert_response :success
  end

  test "should get edit" do
    get edit_github_org_url(@github_org)
    assert_response :success
  end

  test "should update github_org" do
    patch github_org_url(@github_org), params: { github_org: { name: @github_org.name } }
    assert_redirected_to github_org_url(@github_org)
  end

  test "should destroy github_org" do
    assert_difference("GithubOrg.count", -1) do
      delete github_org_url(@github_org)
    end

    assert_redirected_to github_orgs_url
  end
end
