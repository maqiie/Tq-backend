class Transaction < ApplicationRecord
 belongs_to :agent, optional: true  # as per your existing setup
  belongs_to :creator, class_name: 'User', foreign_key: 'creator_id', optional: true
end
