# models/agent_transaction.rb
class AgentTransaction < ApplicationRecord
  belongs_to :agent

  validates :closing_balance, presence: true

  before_create :set_opening_balance

  def set_opening_balance
    last_transaction = agent.agent_transactions.last
    self.opening_balance = last_transaction ? last_transaction.closing_balance : 0
  end
end