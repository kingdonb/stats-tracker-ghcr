require 'rails_helper'

RSpec.describe "landings/new", type: :view do
  before(:each) do
    assign(:landing, Landing.new(
      email: "MyString",
      twitter: "MyString",
      fediverse: "MyString",
      accept_coc: false,
      printed_stickers_already: false
    ))
  end

  it "renders new landing form" do
    render

    assert_select "form[action=?][method=?]", landings_path, "post" do

      assert_select "input[name=?]", "landing[email]"

      assert_select "input[name=?]", "landing[twitter]"

      assert_select "input[name=?]", "landing[fediverse]"

      assert_select "input[name=?]", "landing[accept_coc]"

      assert_select "input[name=?]", "landing[printed_stickers_already]"
    end
  end
end
