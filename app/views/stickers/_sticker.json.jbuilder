json.extract! sticker, :id, :image_url, :created_at, :updated_at
json.url sticker_url(sticker, format: :json)
