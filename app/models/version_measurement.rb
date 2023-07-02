class VersionMeasurement < ApplicationRecord
  belongs_to :package
  belongs_to :version
end
