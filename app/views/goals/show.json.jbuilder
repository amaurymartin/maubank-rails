# frozen_string_literal: true

json.goal do
  json.partial! goal, as: :goal
end

json.links do
  json.user user_path(goal.user)
end
