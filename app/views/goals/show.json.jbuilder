# frozen_string_literal: true

json.goal do
  json.partial! goal, as: :goal

  json.links do
    json.self goal_path(goal)
  end
end
