module PermanentRepel
  module_function

  def active?
    $PermanentRepel && $PermanentRepel[:active] &&
      $PermanentRepel[:type] == :REPELCHARM
  end

  def toggle
    $PermanentRepel ||= { :active => false, :type => nil }
    $PermanentRepel[:active] = !active?
    $PermanentRepel[:type] = $PermanentRepel[:active] ? :REPELCHARM : nil
    if active?
      pbMessage(_INTL("You activated the Repel Charm."))
      pbMessage(_INTL("Wild Pokémon will not appear until you deactivate it."))
    else
      pbMessage(_INTL("You deactivated the Repel Charm."))
      pbMessage(_INTL("Wild Pokémon will appear normally."))
    end
    active?
  end
end

alias permanent_repel_original_pb_encounter pbEncounter
def pbEncounter(enc_type, only_single = true)
  return false if PermanentRepel.active?
  permanent_repel_original_pb_encounter(enc_type, only_single)
end

$PermanentRepel ||= { :active => false, :type => nil }

SaveData.register(:permanent_repel) do
  reset_on_new_game
  save_value { $PermanentRepel }
  load_value { |value| $PermanentRepel = value || { :active => false, :type => nil } }
  new_game_value { { :active => false, :type => nil } }
end

ItemHandlers::UseFromBag.add(:REPELCHARM, proc { |_item|
  PermanentRepel.toggle
  next 1
})

ItemHandlers::UseInField.add(:REPELCHARM, proc { |_item|
  PermanentRepel.toggle
  next true
})

class PokemonEncounters
  alias permanent_repel_encounter_triggered encounter_triggered?
  def encounter_triggered?(enc_type, repel_active = false, triggered_by_step = true)
    if PermanentRepel.active?
      @chance_accumulator = 0
      return false
    end
    permanent_repel_encounter_triggered(enc_type, repel_active, triggered_by_step)
  end

  alias permanent_repel_allow_encounter allow_encounter?
  def allow_encounter?(enc_data, repel_active = false)
    return false if PermanentRepel.active?
    permanent_repel_allow_encounter(enc_data, repel_active)
  end
end
