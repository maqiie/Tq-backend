# models/agent.rb
class Agent < ApplicationRecord
  belongs_to :user
  has_many :agent_transactions
  has_many :commissions


  has_many :transactions
  has_many :debtors

  validates :name, presence: true
  validates :type_of_agent, presence: true  # Bank, Mobile Provider, etc.

  def current_balance
    agent_transactions.last&.closing_balance || 0
  end
end