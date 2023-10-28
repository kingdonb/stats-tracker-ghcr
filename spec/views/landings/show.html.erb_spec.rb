require 'rails_helper'

RSpec.describe "landings/show", type: :view do
  before(:each) do
    assign(:landing, Landing.create!(
      email: "Email",
      twitter: "Twitter",
      fediverse: "Fediverse",
      accept_coc: false,
      printed_stickers_already: false
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/Twitter/)
    expect(rendered).to match(/Fediverse/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
  end
end
