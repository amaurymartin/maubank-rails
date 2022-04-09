# frozen_string_literal: true

json.goals do
  json.array! goals do |goal|
    json.partial! goal, as: :goal

    json.links do
      json.self goal_path(goal)
    end
  end
end
