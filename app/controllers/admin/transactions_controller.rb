class Admin::TransactionsController < ApplicationController
  before_action :authenticate_admin!

  def download
    # Here, you could generate a CSV or other format for transactions
    @transactions = Transaction.all
    send_data generate_csv(@transactions), filename: "transactions-#{Date.today}.csv"
  end

  private

  def generate_csv(transactions)
    CSV.generate(headers: true) do |csv|
      csv << ['Agent ID', 'Opening Balance', 'Closing Balance', 'Date']
      transactions.each do |transaction|
        csv << [transaction.agent_id, transaction.opening_balance, transaction.closing_balance, transaction.date]
      end
    end
  end
end
