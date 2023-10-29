require "rails_helper"

RSpec.describe StickersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/stickers").to route_to("stickers#index")
    end

    it "routes to #new" do
      expect(get: "/stickers/new").to route_to("stickers#new")
    end

    it "routes to #show" do
      expect(get: "/stickers/1").to route_to("stickers#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/stickers/1/edit").to route_to("stickers#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/stickers").to route_to("stickers#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/stickers/1").to route_to("stickers#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/stickers/1").to route_to("stickers#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/stickers/1").to route_to("stickers#destroy", id: "1")
    end
  end
end
