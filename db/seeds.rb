# # Clear existing data to avoid duplicates
# User.destroy_all
# Agent.destroy_all
# Commission.destroy_all
# Transaction.destroy_all
# Debtor.destroy_all

# # Create Users
# puts "Creating Users..."

# admin = User.create!(
#   name: 'Admin User',
#   email: 'admin@example.com',
#   uid: 'admin@example.com',
#   role: 'admin',
#   password: 'password'
# )
# puts "Admin user created: #{admin.email}"

# employee1 = User.create!(
#   name: 'Employee One',
#   email: 'employee1@example.com',
#   uid: 'employee1@example.com',
#   role: 'employee',
#   password: 'password'
# )
# puts "Employee user created: #{employee1.email}"

# employee2 = User.create!(
#   name: 'Employee Two',
#   email: 'employee2@example.com',
#   uid: 'employee2@example.com',
#   role: 'employee',
#   password: 'password'
# )
# puts "Employee user created: #{employee2.email}"

# # Agents
# puts "Creating Agents..."
# agents = Agent.create!(
#   [
#     { name: 'Agent Smith', type_of_agent: 'Sales' },
#     { name: 'Agent Johnson', type_of_agent: 'Support' },
#     { name: 'Agent Brown', type_of_agent: 'Field' }
#   ]
# )
# puts "Agents created: #{agents.map(&:name).join(', ')}"

# # Commissions
# puts "Creating Commissions..."
# 30.times do
#   Commission.create!(
#     amount: rand(100..1000),
#     agent: agents.sample,  # Link commission to a random agent
#     created_at: rand(6.months.ago..Time.now)
#   )
# end
# puts "Commissions created."

# # Transactions (Ensure user exists before linking to transactions)
# puts "Creating Transactions..."
# 20.times do
#   user = User.where(role: 'employee').sample  # Random employee
#   if user.nil?
#     puts "Warning: No user found for transaction!"
#   else
#     Transaction.create!(
#       amount: rand(50..500),
#       user: user,  # Link transaction to an employee
#       created_at: rand(6.months.ago..Time.now)
#     )
#     puts "Transaction created for user #{user.email}."
#   end
# end

# # Debtors
# puts "Creating Debtors..."
# 10.times do
#   Debtor.create!(
#     name: Faker::Name.name,
#     debt_amount: rand(1000..10000),
#     created_at: rand(6.months.ago..Time.now)
#   )
# end
# puts "Debtors created."

# puts "Seeding complete!"
