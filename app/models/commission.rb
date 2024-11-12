class Commission < ApplicationRecord
  belongs_to :agent

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :month, presence: true
  validates :year, presence: true
end
