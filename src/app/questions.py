# might need package stuff here

from dataclasses import dataclass
from typing import Literal


@dataclass
class Question:
    template_id: str  # snake_case, unique, ends _v1
    topic: str  # dotted topic path, see topic list
    difficulty_tier: Literal["easy", "medium", "hard"]
    difficulty_levers: dict
    cosmetic_slots: dict  # surface-only variation
    parameters: dict  # math variation, sampled
    guards: list  # reject a sample if any is false—list of python-evaluable boolean strings over the parameters
    stem: str  # the question text, slots in braces
    derived: dict  # name: "python expression over parameters"
    distractors: list  # wrong answers AS RULES;exactly 3 distractors -> 4 options total; list of dicts
    authoring_notes: str  # see required-notes section
    is_modeling: bool = False  # True if math is wrapped in a real-world scenario; default val means must come last


# add an init?
