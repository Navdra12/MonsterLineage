# Monster Lineage Sandbox — Game Design Specification

Date: 2026-09-14
Status: Revised design specification awaiting final review before implementation planning

## 1. Product vision

A 2D creature-first sandbox/roguelike about survival, reproduction, inheritance, evolution, family lines, and the long history of a living world. The player starts as a very small spider-like creature and controls one concrete individual at a time. Across generations, the lineage can diverge into arachnids, humanoid monster-girl forms, giant chimeras, dragon-like organisms, magical life, or other body plans that may no longer visibly resemble the original spider.

The game has no final victory state. It is an open-ended sandbox in which major lineage milestones act as long-term accomplishments: founding a stable new species, changing body plan completely, creating a civilization, achieving forms of immortality, discovering the current world's magic, or creating a consciousness that persists across bodies.

The core promise is that even after the lineage becomes politically important, technologically capable, or biologically extreme, the player still inhabits and directly controls one living creature rather than becoming an abstract empire cursor.

## 2. Design pillars

### 2.1 Creature-first play

The immediate game must remain enjoyable at the scale of one body: moving, hiding, hunting, feeding, getting injured, using anatomy, finding shelter, interacting with other creatures, raising offspring, and surviving.

### 2.2 Generational evolution

Large evolutionary changes happen between generations. A living creature may grow, molt, strengthen existing organs, heal, or experience limited physiological adaptation, but major body-plan changes occur in descendants.

### 2.3 Persistent lineage

The player is attached to a lineage rather than one immortal protagonist. On generational transition the former player character continues as an autonomous NPC, carrying the personality, preferences, memories, relationships, and habits produced by the player's prior actions.

### 2.4 Living world

Species, populations, factions, ecosystems, family branches, settlements, ruins, technologies, and cultures continue to change without the player's direct control. Distant regions use lower-detail simulation rather than full per-creature simulation.

### 2.5 Discovery instead of omniscience

The UI should expose what the current creature or its culture actually knows. Evolutionary potential, distant political conditions, magic, and biological interactions should often be discovered through observation, teaching, experimentation, records, and inherited knowledge.

### 2.6 Biological diversity changes gameplay

A different species or body plan is not merely a new sprite and stat package. It can change locomotion, senses, combat, diet, reproduction, lifecycle, equipment compatibility, remains after death, social structure, and relationship with technology.

## 3. World structure and time

The world consists of large persistent procedural zones rather than one uninterrupted map or discrete disposable roguelike floors. Example zones include forests, caves, wetlands, rocky regions, ruins, settlements, and deep underground systems.

The player moves between zones. Changes remain when the player leaves: nests persist, populations can rise or fall, settlements can change ownership, relatives can migrate, and resources can be depleted or recover.

Simulation has multiple levels of detail:

- The active zone receives detailed real-time creature simulation.
- Nearby or recently relevant zones use simplified creature and faction simulation.
- Distant regions are updated through aggregated historical steps that track population, food, resources, conflict, rulers, migration, technology, culture, and other high-level variables.

This preserves long-term world history without simulating every creature every second.

## 4. Initial world generation and history

A new world is generated from a seed and configurable generation parameters. Before the player appears, the world runs through accelerated historical simulation. Depending on settings, this prehistory may cover decades or centuries.

The prehistory can produce:

- established and collapsed factions;
- wars, alliances, migrations, and territorial changes;
- extinct populations and locally adapted populations;
- dynasties and leadership histories;
- ruined nests, settlements, monuments, archives, graves, and preserved remains;
- technologies already known by some cultures;
- dormant precursor traces;
- species that have locally diverged from their manually authored base species.

Longer prehistory does not guarantee a more powerful world. Civilizations may rise and collapse before the player is born.

## 5. Species, populations, and factions

These are distinct concepts.

### 5.1 Species

A species is a stable biological lineage or recognizable morphology with authored biological rules. Core species are hand-designed so that they retain clear identity and meaningful lifecycle differences.

The generator may vary local forms of a species through size, coloration, diet, behavior, lifespan, reproduction, genes, and local adaptations.

### 5.2 Population

A population is a regional biological population of a species. It may diverge over time and develop local traits different from distant populations of the same species.

### 5.3 Faction

A faction is a social organization such as a nest, tribe, flock, clan, city, kingdom, colony, or other polity. Multiple hostile factions may belong to the same species, and a faction may eventually contain multiple compatible species.

Faction state can include population, territory, food, resources, leadership, culture, diplomatic relations, technology, known magic, strategic goals, and internal succession pressures.

The player's relatives can found their own nests and become independent factions. Blood relation creates history and possible claims, not automatic loyalty.

## 6. Core player loop

The intended long-form loop is:

1. Survive in the current body.
2. Find food and shelter.
3. Grow and use the body's capabilities.
4. Form relationships, memories, habits, and personality traits.
5. Explore other species, populations, factions, and environments.
6. Reproduce under the current biological and social rules.
7. Receive a clutch or other species-appropriate offspring group.
8. Raise, lose, protect, neglect, compete with, or observe descendants.
9. Choose a living descendant as the next controlled body.
10. Continue the lineage while the former body becomes an NPC.

This loop can later change radically for species with nonstandard lifecycles, biological immortality, consciousness transfer, collective minds, or other endgame biological/magical mechanisms.

## 7. Starting creature and early identity

Version 0.1 always begins with a small spider-like creature. Alternative starting organisms are a future expansion.

The starting creature is weak enough that many creatures are predators rather than prey. The first hours emphasize hiding, finding food, using small spaces, web mechanics, sensing danger, and choosing when not to fight.

The arachne form with a humanoid torso is not the automatic first evolution and may never appear in a lineage. It is only one possible body-plan direction among many.

## 8. Genetics and evolution model

The game does not attempt chromosome-level biological realism. The genetic system is a gameplay model with modular inherited traits, body plans, compatibility rules, and developmental constraints.

### 8.1 Body plan

A body plan defines fundamental anatomy and capability structure, such as:

- limb layout;
- head and torso arrangement;
- locomotion modes;
- internal versus external support structures;
- manipulation organs;
- wings, tail, abdomen, tentacles, or other major structures;
- feeding apparatus;
- reproductive anatomy and lifecycle constraints.

The initial lineage uses an arachnid body plan.

### 8.2 Traits

Traits sit on top of the body plan. Examples include:

- eye arrangement;
- chitin properties;
- venom organs;
- web organs;
- size and growth rate;
- metabolism;
- regeneration;
- thermoregulation;
- respiratory systems;
- neural development;
- manipulators;
- sensory organs;
- limb specialization;
- tissue density.

A trait is not the same thing as an evolution or body-plan transition. Increased forelimb dexterity may be a trait; true precision manipulators may be a major evolutionary feature; a humanoid upper torso is a body-plan change.

### 8.3 Within-life change

During one life the creature can grow, molt, heal, strengthen existing structures, suffer damage, and undergo limited physiological change. Major new body structures and fundamental body-plan changes are reserved for descendants.

### 8.4 Offspring variation

Each offspring receives its own genome variant based on:

- the player's lineage genome;
- compatible material from the reproductive partner or other genetic source;
- recessive and latent traits;
- recombination;
- developmental conditions;
- a controlled mutation chance.

A clutch may therefore contain a near-copy of the parent, a stronger expression of an existing trait, a rare combination, a weak or unstable combination, a new body-plan transition, or a rare chimera.

### 8.5 Hidden potential

Some genetic potential can remain latent across generations and become relevant only after compatible traits accumulate. The player never receives a complete universal evolution tree.

The evolution interface shows known traits, known potential, and incomplete or unknown possibilities based on current knowledge.

### 8.6 Cross-species evolution

The default world rule is moderate cross-species compatibility. Monster-like sapient species and biologically related organisms provide most ordinary reproductive opportunities. Animals or monsters may contribute narrower physiological traits.

Extremely broad compatibility requires rare evolutionary breakthroughs such as adaptive reproductive biology, genetic assimilation, parasitic development, or chimeric genomes.

This permits late-game paths that can move the lineage from arachnid ancestry toward entirely different organisms, including dragon-like forms or other stable new species.

### 8.7 Stable new species

A lineage can become a new stable species when its defining anatomy and traits reproduce reliably within the new population rather than requiring repeated external hybridization.

The player may name such a lineage/species, and it can later become a candidate for the global Legacy Library.

## 9. Life-history strategies

Evolution affects not only anatomy but the species' life strategy.

Possible trajectories include:

- colonial: many offspring, specialized roles, lower individual investment;
- family-oriented: small family groups, longer childhood, greater parental investment;
- solitary: rare reproduction, powerful adults, low population density;
- long-lived: slow reproduction and high individual survival investment;
- biologically immortal: negligible senescence and new within-life transformation methods.

These strategies impose tradeoffs. A solitary apex organism can be individually much stronger than a colonial relative but is vulnerable to low reproduction and population collapse.

## 10. Intelligence and cognition

Cognition can evolve rather than being assumed at full human level from the beginning.

A simple staged model is preferred over simulating intelligence numerically at extreme detail. Example capability bands:

- instinctive;
- cunning;
- sapient;
- advanced.

Increasing cognition opens new gameplay systems such as deliberate teaching, language, long-range planning, complex social organization, diplomacy, writing, technology, research, and governance.

A non-humanoid creature may be fully sapient. Intelligence does not imply human anatomy.

## 11. Immediate gameplay, combat, and survival

Gameplay is real-time with an active pause or strong slowdown for tactical decisions.

### 11.1 Anatomy-driven actions

Different body plans create different action sets rather than merely modifying combat statistics.

Early spider capabilities can include:

- rapid movement;
- wall and ceiling traversal where terrain supports it;
- web placement;
- ambush;
- bite;
- venom;
- retreat through small spaces.

Later forms may gain grappling, powerful leaps, improved webs, manipulators, equipment use, wings, tails, ramming, armor, or other anatomy-specific actions.

### 11.2 Hunting

Prey and predators should reward different hunting strategies. Webbing, poisoning, isolating targets, stealth, pursuit, baiting, and escape can all matter.

The player may perceive the world through anatomy-specific sensory systems such as vibration, scent, vision, sound, tracks, heat, and eventually world-specific magical senses.

### 11.3 Injury

The game uses a compromise between a single HP bar and full Dwarf Fortress anatomy simulation.

It tracks overall condition and meaningful body-part damage, including relevant conditions such as bleeding, poisoning, fractures, impaired limbs, or loss of structures. Species rules determine what injuries mean. A spider may survive the loss of a leg and regenerate it at a later molt; a slime-like organism may not have bones at all.

### 11.4 Needs

Survival needs remain selective rather than becoming a many-bar micromanagement simulator. Core needs include energy/hunger and species-dependent requirements such as water, humidity, temperature, sunlight, blood, minerals, or magical energy.

The needs themselves can therefore change as the lineage changes species.

## 12. Web system

Webs are the defining early mechanical toolkit and can support:

- traps;
- alarms through vibration;
- movement routes;
- passage control;
- prey restraint;
- cocoons;
- food preservation;
- egg protection;
- construction;
- later crafting materials.

Web genetics may modify strength, adhesion, elasticity, environmental resistance, toxicity, or other properties.

## 13. Reproduction and offspring

Reproduction has four conceptual stages: compatibility, interaction, offspring formation, and development.

### 13.1 Species-specific interaction

There is no universal identical "mate" interaction for every species. Depending on biology and culture, reproduction may require trust, courtship, dominance, ritual, resource exchange, shared nesting, symbiosis, or other species-specific conditions.

### 13.2 Clutches and developmental groups

A clutch contains multiple offspring where appropriate for the species. Each offspring may differ genetically. The player can influence probabilities through partner choice, lineage history, incubation conditions, selection, later biological knowledge, technology, or world-specific magic, but cannot simply choose an exact perfect build.

### 13.3 Tradeoffs and harmful mutations

Not every mutation is beneficial. New combinations can create locomotion problems, high energy demands, infertility, fragility, developmental instability, or other costs. Evolution is therefore not a permanent accumulation of bonuses.

### 13.4 Any living daughter can become the next body

The player may transfer to any living daughter, including a newly hatched child. This intentionally makes childhood a playable survival phase rather than a skipped timer.

A child may be dependent on adults, unable to hunt effectively, vulnerable to siblings, forced to steal food, or pushed toward harsh choices such as cannibalism during famine.

## 14. Generational transfer and lineage survival

The player's choice of next body and the nest's political succession are separate systems.

Once a living daughter exists, the player may voluntarily transfer control to her at any point; the transfer is irreversible. After generational transfer, the former player character becomes an NPC. Control cannot be transferred back.

If the current controlled creature dies without living daughters, the lineage may continue through another accessible living relative: sisters, nieces, aunts, cousins, or other sufficiently connected branches.

A true run-ending failure occurs only when no eligible living lineage remains.

## 15. Personality and behavioral history

Personality belongs to an individual, not the genome. It develops from repeated player behavior and significant experiences.

Possible traits include territoriality, protectiveness, sociality, cannibalism, caution, dominance, curiosity, opportunism, or risk aversion.

Some traits are visible once obvious. Others remain hidden until enough evidence exists or a situation exposes them.

The system should not reduce a lifetime to one binary flag. One act of emergency cannibalism is different from a lifetime of routinely consuming offspring.

## 16. Food preference and aversion

Each creature accumulates a food-history profile based on what it eats and under what circumstances.

Factors can include:

- frequency of consumption;
- nutritional benefit;
- whether the food prevented starvation;
- poisoning or disease;
- social taboo;
- relationship to the consumed creature;
- repeated positive or negative outcomes.

After the creature becomes an NPC, these preferences influence autonomous food choice. A former player character that mostly hunted harpies may prefer harpy meat; a survivor of poisoning may avoid the responsible food source.

## 17. Relationships and memory

Relationships should preserve reasons rather than collapse into a single friendship score. A creature may love a daughter, distrust her judgment, fear her strength, and still refuse to name her heir.

Personal memory stores significant events rather than an exact log of every second. Important memories may include locations, predators, allies, betrayals, deaths, successful hunting strategies, clutches, territories, or major disasters.

After control transfer, the NPC AI uses personality, needs, preferences, relationships, knowledge, and remembered strategies to make decisions that remain recognizably connected to how the player previously lived.

## 18. Knowledge and cultural inheritance

Biological inheritance, personality, and knowledge are separate systems.

A child initially knows only what it directly experiences, what is instinctive, and what other creatures successfully teach or communicate.

Knowledge storage can progress through:

1. oral teaching;
2. records and writing;
3. libraries and archives;
4. specialized cultural knowledge systems;
5. memory banks or equivalent late-game mechanisms.

A sufficiently advanced memory bank may transfer detailed autobiographical memory. Very late systems may permit consciousness transfer, creating a persistent personality across bodies.

Loss of teachers, records, or archives can cause knowledge to disappear from a lineage.

## 19. Nests, bases, and the hybrid hub

Base building has medium depth. The player can establish and expand nests, burrows, chambers, defensive spaces, storage, incubation areas, archives, medical or molting spaces, and other meaningful rooms without micromanaging every worker as in a full city builder.

The game uses a hybrid presentation:

- ordinary exploration and combat are top-down;
- important nest, body, lineage, and evolution views use larger side-view or three-quarter character presentation.

The nest acts as a diegetic home and as a gateway to deeper interfaces.

Possible nest functions include:

- incubation chamber;
- molting/body chamber;
- social chamber;
- lineage hall;
- archive/library;
- later memory bank;
- preserved remains or ancestor spaces.

This solves the readability problem of top-down monster-girl and chimera forms without giving up top-down sandbox play.

## 20. Parallel family branches

Sisters, aunts, nieces, and other relatives may create independent nests and factions. Their descendants can evolve in different directions from the player's active branch.

Parallel branches may become allies, competitors, enemies, clients, predators, or unrelated powers over time. They can support different heirs, raid one another, steal eggs, trade, exchange knowledge, or fight over territory.

The lineage view tracks known branches, but information can become stale if contact is lost.

## 21. Succession and legitimacy

The matriarch or current leader may name an official heir independently of the body selected by the player.

Selection can depend on:

- personality of the ruler;
- affection and trust;
- strength;
- political support;
- culture;
- perceived competence;
- biological suitability;
- historical events.

Choosing the official heir can grant access to the nest, resources, supporters, and legitimacy. Choosing another daughter may result in reduced status, exile, a new nest, a succession dispute, factional split, duel, or civil war.

Support is distributed among concrete relatives, followers, and allied branches rather than represented only by one global number.

## 22. Faction diplomacy and governance

The player's lineage can eventually participate in light strategic management rather than full city-builder micromanagement.

The player can influence priorities such as food acquisition, nest expansion, migration, diplomacy, reproductive norms, major construction, and succession policy, while individual NPCs continue to act autonomously.

Faction relations can include neutrality, trade, passage rights, shared hunting, genetic/reproductive exchange where culturally appropriate, dependency, temporary alliances, territorial conflict, blood feuds, and war.

Biology and culture affect the meaning of diplomatic actions. Egg exchange can be sacred diplomacy in one culture and an atrocity in another.

## 23. Ecology

Ecology uses medium simulation depth.

The world tracks meaningful population and resource pressures without simulating every plant or insect globally. Predation can reduce prey populations, loss of predators can cause prey booms, overpopulation can create famine, and famine can cause migration, lower birth rates, cannibalism, or war.

Local creatures are simulated directly; distant ecological systems use aggregate population models.

## 24. Species-specific lifecycles

Different species can have fundamentally different lifecycles rather than sharing a generic age curve.

Examples include:

- egg to juvenile through multiple molts;
- slime division or biomass budding;
- spore stages;
- host-changing parasites;
- larva to cocoon to adult metamorphosis;
- live birth;
- rare offspring with long maturation;
- regeneration-based persistence.

Changing species can therefore change the rhythm and rules of play.

## 25. Death, permadeath, and remains

Individual death is permanent by default. Important NPCs do not respawn merely because they matter to the story.

Resurrection is possible only as a rare late-game exception created by specific species biology, technology, or world-specific magic. Even then, systems should distinguish true resurrection from corpse animation, memory reconstruction, cloning, regeneration, possession, or consciousness storage.

Remains depend on biology:

- vertebrate-like bodies may decay to bones, teeth, or horns;
- arthropod bodies may leave chitinous shells or mineralized structures;
- fungal bodies may become spore colonies;
- plant-like bodies may dry, root, or become woody remains;
- slime-like species may return biomass to an ancestral pool.

Remains can be food, resources, genetic material, ritual objects, graves, monuments, ancestor reservoirs, necromantic substrates, or architectural material.

Culture determines how factions treat their dead.

## 26. Technology and culture

Technology advances through tools, crafts, metallurgy, complex construction, mechanics, medicine/alchemy, and possibly magic-integrated technology.

The intended technological ceiling is broadly late-medieval to early-Renaissance in capability, without conventional gunpowder firearms becoming standard gameplay.

Technology interacts with anatomy. A humanoid arachne may use ordinary swords and fitted armor. A giant spider chimera cannot simply equip the same items and may require segment armor, body-mounted equipment, carriers, special tools, or purely biological alternatives.

Civilization therefore does not imply becoming humanoid.

Cultures develop norms regarding succession, reproduction, cannibalism, death, outsiders, mutation, trade, warfare, magic, and other repeated social pressures.

## 27. Magic and procedural cosmology

Magic is present by default as hidden world potential. A fully non-magical world is available only as an explicit world-generation setting.

The generator creates underlying magical principles rather than simply choosing a fixed spell list. Possible foundations include materials, bloodlines, dreams, memory, spatial geometry, living connections, death, resonance, or other systems.

The player initially does not know these rules. Magic is discovered through anomalies, organisms, ruins, experiments, materials, inherited adaptations, or contact with factions that have already found part of the system.

Different cultures may interpret the same underlying magic as religion, biology, craft, or science.

### 27.1 Magical evolution

World-specific magic can become part of biological evolution. A lineage may develop organs, symbionts, metabolism, senses, or body structures that interact with the world's magical rules.

This can eventually produce elemental forms, nonstandard bodies, magical regeneration, consciousness mechanisms, phylacteries, collective minds, or other extraordinary states if the current world permits them.

### 27.2 Necromancy and resurrection

A world's magic may permit corpse animation, partial memory restoration, soul-binding, regeneration from remains, phylacteries, or true resurrection. These are not guaranteed universal systems.

NPC factions can discover such systems independently of the player.

## 28. Forms of immortality

There is no single canonical immortality upgrade. Potential endgame accomplishments include:

- biological immortality through negligible senescence;
- regeneration from surviving biomass;
- consciousness transfer into descendants or prepared bodies;
- external consciousness storage such as a phylactery-like mechanism;
- collective minds distributed across many bodies;
- world-specific magical persistence;
- other generated mechanisms.

Biological immortality changes the normal evolutionary loop because the same body may need to evolve through molting, assimilation, organ replacement, symbiosis, or magical transformation rather than generational body-plan replacement.

These paths should introduce tradeoffs rather than being automatic superior endings.

## 29. Legacy Library

The game has a global cross-world library that can preserve player-created biological and cultural achievements for later world generation.

A saved legacy is a reusable template, not a literal copy of every NPC and resource from the original save.

A legacy template may contain:

- stable species genome/body-plan profile;
- characteristic local variants;
- faction culture;
- governance tendencies;
- technology level;
- magical knowledge where compatible with the new world's laws;
- characteristic architecture;
- common equipment adaptations;
- historical identity and notable traits.

Saved legacy species and factions can reappear in later worlds when enabled.

## 30. World Impact Rating

Legacy entries receive a world-impact classification based on multiple dimensions rather than one combat stat. Inputs can include individual physical power, reproductive speed, lifespan, technology, magical capacity, expansion ability, resilience, and social organization.

Suggested categories:

- Tier I — Minor;
- Tier II — Standard;
- Tier III — Dominant;
- Tier IV — Apex;
- Tier V — Precursor / World-Shaping.

Standard generation primarily permits Tier I–II as normal active starting powers. Tier III can appear more rarely. Tier IV–V usually appear indirectly as ruins, extinct precursors, sealed entities, tiny isolated remnants, ancient remains, lost technology, or legends.

An explicit unbalanced setting allows these restrictions to be removed.

## 31. New-world generation settings

World creation has a quick mode and an advanced mode.

### 31.1 Quick mode

Quick mode exposes seed, world size, difficulty, and broad presets such as Balanced, Harsh Ecology, High Magic, or Wild Legacy.

### 31.2 Advanced settings

Advanced settings can include:

- world size;
- region count;
- biome and climate diversity;
- cave and underground density;
- water prevalence;
- season severity;
- natural disaster frequency;
- prehistory duration;
- species density;
- sapient species frequency;
- ecological pressure;
- natural evolutionary drift;
- faction density;
- warfare frequency;
- expansion tendency;
- technological development rate;
- starting civilization density;
- magic saturation;
- interspecies compatibility difficulty;
- simulation speed parameters.

### 31.3 Legacy modes

- Off: use only the game's base content.
- Balanced: allow ordinary legacy species/factions as active populations while stronger legacies appear mainly through historical traces.
- Wild: allow any saved legacy to become an active starting power.

The player may pin selected legacy entries so they are guaranteed to leave some form of trace in the generated world. In Balanced mode this does not guarantee that the pinned legacy survives as a living faction.

### 31.4 World Power Budget

A world-power setting controls how aggressively generation permits powerful starting entities and states:

- Low;
- Standard;
- High;
- Unrestricted.

### 31.5 Magic settings

Default: magic exists but is hidden and procedurally defined.

Optional saturation settings include Very Rare, Standard, and High Saturation. No Magic is an explicit opt-in setting.

The player controls visibility/frequency, not the actual generated laws of magic.

### 31.6 Hidden world secrets

By default the player does not receive omniscient generation output. Existing hidden species, surviving precursors, magical rules, unknown ruins, and distant faction states remain unknown until discovered.

A debug/sandbox option can expose them.

For reproducibility, a shared world code should include the seed, generation settings, game/world-generation version, and the relevant Legacy Library snapshot or identifiers. The same inputs should reproduce the same base generated world within the same compatible version.

## 32. Procedural languages, naming, and localization

Procedural names are generated from cultural and linguistic profiles rather than from one universal random-syllable generator. Naming should carry historical information about species, populations, factions, territories, settlements, individuals, and earlier owners of a place.

### 32.1 Language and naming profiles

A culture or language family can define data-driven naming rules such as:

- phoneme or syllable inventories;
- permitted word shapes;
- common prefixes, suffixes, compounds, and honorifics;
- personal-name conventions;
- lineage and family-name conventions;
- faction-name templates;
- settlement and territory-name templates;
- titles and forms of address;
- transliteration rules for the player's interface language;
- semantic concepts frequently used in names.

A species does not automatically equal one language. Several factions of the same species may speak different languages, while a multi-species civilization may share one language or develop mixed naming traditions.

Language profiles should be authored enough to have recognizable character while remaining combinatorial and data-driven.

### 32.2 Semantic name generation

Important generated names should retain semantic structure instead of being stored only as final display strings.

A place may be named for:

- geography or climate;
- an important resource;
- a founder or ruler;
- a local species;
- a historical battle, migration, disaster, or death;
- a religious or magical phenomenon;
- a previous faction;
- a characteristic color, material, smell, sound, or ecological feature.

A faction may be named after a founder, territory, symbol, ancestry, profession, clutch, nest, political form, oath, historical event, or religious concept. Different cultures choose from these patterns with different weights.

This avoids repetitive constructions such as `Adjective + Noun Tribe` and permits names whose form reflects the culture that created them.

### 32.3 Historical names, endonyms, and exonyms

The same entity may have multiple names at once:

- an endonym used by its inhabitants;
- an exonym used by another culture;
- a current official name;
- older historical names;
- a translated semantic name known to the player's culture.

Names can change when a territory is conquered, a dynasty changes, a disaster redefines the place, a culture assimilates another, or a settlement changes function. Older names remain in historical records and memories.

This allows a territory to preserve visible history. A valley may have an ancient local name, a later imperial administrative name, and a modern colloquial name simultaneously.

### 32.4 Personal naming conventions

Individuals do not all need human-like birth names. Naming rules may depend on lifecycle and culture.

Examples include:

- a name assigned at hatching;
- a temporary juvenile name replaced after a molt or coming-of-age event;
- a matrilineal or nest-derived name;
- a title earned after a deed;
- a numbered clutch identity in highly colonial societies;
- no individual name at all until sufficient cognition or social complexity evolves.

A creature's naming history should be recordable so an important NPC can be recognized across title changes, succession, migration, or cultural assimilation.

### 32.5 Mixed languages and cultural drift

Languages and naming traditions can change historically. Long contact, migration, conquest, intermarriage, or faction merger may create mixed naming profiles.

The system does not need a full natural-language evolution simulator. It only needs enough inheritance and weighted borrowing to let later names visibly reflect cultural history.

### 32.6 Legacy Library integration

A saved Legacy species or faction may preserve its language/naming profile as part of the template. If it reappears in a later world, its characteristic names can remain recognizable while still adapting to the new world's history.

A legacy faction used only as an extinct precursor can therefore leave ruins, inscriptions, place names, titles, or loanwords without requiring the original civilization to survive.

### 32.7 Player-facing localization architecture

All player-facing authored text must use localization identifiers rather than hardcoded display strings. Ukrainian can be the first complete language, but the data and UI must be designed so additional localizations can be added without rewriting gameplay code.

Localization applies to:

- UI labels and menus;
- traits, organs, statuses, injuries, and abilities;
- species descriptors;
- event text;
- tutorials and tooltips;
- faction and political terminology;
- generated-name semantic components;
- relationship and personality descriptions;
- knowledge-codex entries;
- world-generation options.

Stable internal IDs remain language-independent.

### 32.8 Grammar-aware procedural localization

Procedural text must not be built by naively concatenating already-translated words. Languages differ in word order, grammatical gender, number, cases, articles, agreement, and inflection.

Generated content therefore passes semantic arguments into a locale-specific template. For example, the game can internally represent a faction name as a nest-type construction whose semantic components are `silver` and `web`. Ukrainian, English, Polish, or Japanese localizations may render those components in different order and grammatical forms.

Where a localization needs it, lexical entries can provide metadata or forms such as:

- grammatical gender;
- singular/plural behavior;
- relevant case forms or inflection class;
- adjective agreement information;
- animate/inanimate behavior;
- capitalization rules.

The implementation should support locale-specific grammar helpers rather than putting Ukrainian-specific grammar rules into simulation code.

### 32.9 In-world languages versus UI languages

The language spoken by an in-world culture is distinct from the language selected in the game's settings.

The player interface may be Ukrainian while a faction speaks a fictional generated language. Depending on the controlled creature's knowledge, the UI may show:

- only the untranslated endonym;
- a transliterated form;
- a partial interpretation;
- the full translated meaning after the language is learned.

This lets language knowledge become part of discovery without preventing ordinary localization.

### 32.10 0.1 requirement

Version 0.1 does not need full historical language drift or large-scale procedural linguistics. It does require the architectural foundation:

- no gameplay-critical user-facing text hardcoded into logic;
- Ukrainian localization resources as the initial complete locale;
- locale-switching support in the UI layer;
- a small data-driven naming profile sufficient for prototype individuals, nests, groups, and local territories;
- semantic/template-based generated names rather than final-language string concatenation.

Full cultural language evolution, exonyms, historical renaming, and Legacy naming inheritance remain later systems.

## 33. User interface and presentation

The UI follows the rule: minimal at the surface, deep on demand.

### 33.1 Main HUD

The ordinary HUD should show only immediate survival and action information such as condition, energy/hunger, meaningful injuries, active abilities, and time state.

### 33.2 Body screen

A large side-view or three-quarter character view shows anatomy, visible mutations, injuries, organs, and functional body parts. This is the primary way to appreciate visual evolution that would be less readable in top-down gameplay.

### 33.3 Evolution screen

The player sees current traits, known potential, and unknown areas. The game does not reveal the entire universal evolution space.

Before offspring hatch, the game can provide probabilistic biological predictions instead of exact outcomes.

### 33.4 Hub presentation

Important nest interactions can use larger side-view scenes showing the matriarch, offspring, siblings, partners, eggs, remains, trophies, and nest structures.

### 33.5 Lineage screen

The lineage interface supports both close family inspection and centuries-scale branch history. Known branch states may include active, independent, allied, hostile, unknown, or extinct. Distant information can become outdated.

### 33.6 World and faction knowledge

Maps and faction pages display only known information. Contact timestamps matter; political and population data may be stale.

### 33.7 Knowledge Codex

The lineage's codex can track discovered species, traits, food, toxins, diseases, materials, technologies, magical phenomena, factions, and historical events. Knowledge can be lost if its carriers and records are destroyed.

## 34. Active pause

The player can slow or pause combat to inspect immediate threats, select an ability, choose a movement target, select an attack target or body part where relevant, inspect injuries, change a stance, or use an item.

This remains control of one creature, not RTS control of the whole colony.

## 35. Major accomplishments instead of a final victory

The sandbox has no required ending. Long-term milestones can include:

- first stable humanoid-derived arachnid form;
- first stable non-arachnid species descended from the original spider;
- founding an independent lineage civilization;
- surviving for a major historical span;
- creating a stable multi-lineage chimera;
- discovering the world's magical principles;
- creating a biological immortal;
- transferring consciousness;
- creating a collective mind;
- producing a world-shaping faction;
- preserving a new species/faction into the Legacy Library.

These are achievements and historical milestones, not mandatory win conditions.

## 36. Version 0.1 vertical slice

Version 0.1 exists to answer one question: is the immediate generation loop enjoyable before the full simulation is built?

### 36.1 Included scope

- Godot-based 2D top-down prototype with large-character side-view screens.
- One procedural environment combining forest and underground burrows.
- One starting small spider body plan.
- Real-time movement with active pause/slowdown.
- Basic climbing/traversal appropriate to the prototype environment.
- Web placement and basic web interaction.
- Bite and simple venom.
- Hunger/energy.
- A lightweight injury model.
- Small prey.
- At least one dangerous predator.
- Two or three additional intelligent or semi-intelligent biological groups sufficient to test compatibility and interaction.
- One burrow that can become a basic nest.
- One reproduction path sufficient to create a clutch.
- Approximately 8–12 inherited traits.
- Approximately 3–4 meaningful second-generation evolutionary directions.
- Multiple genetically distinct offspring in a clutch.
- Ability to transfer into any living daughter, including a hatchling.
- Former player body becomes an NPC after transfer.
- Minimal personality/history tracking.
- Minimal food-preference learning.
- Minimal memory needed to test post-transfer behavior.
- Death fallback to another living eligible relative where one exists.
- Basic lineage screen.
- Large side-view body/nest presentation sufficient to see evolutionary differences.
- Localization-ready text/resource layer with Ukrainian as the initial complete locale.
- Basic data-driven naming profiles for prototype individuals, nests, groups, and local territories.

### 36.2 Explicitly excluded from 0.1

- full multi-region geopolitics;
- complex states and kingdoms;
- full historical world generation;
- deep technology trees;
- procedural magic;
- Legacy Library;
- immortality systems;
- large colony simulation;
- hundreds of species;
- complete civilization management;
- full precursor systems;
- full cross-world meta-progression.
- full historical language drift, exonym simulation, or large-scale procedural linguistics.

The architecture should avoid obvious dead ends for these future systems, but 0.1 must not implement them prematurely.

### 36.3 Success criteria

The vertical slice succeeds if:

1. Playing a weak spider is enjoyable before advanced evolution exists.
2. Webs, hunting, hiding, injury, and feeding create meaningful decisions.
3. Reproduction produces offspring that feel meaningfully different rather than like random stat rerolls.
4. Choosing a daughter creates a genuine change in play.
5. Playing as a hatchling can produce different pressures and personality history from starting as an adult.
6. The former player body behaves recognizably according to the player's prior behavior after becoming an NPC.
7. The side-view presentation makes body evolution visually legible despite top-down exploration.
8. The lineage can survive at least several generations without requiring the future large-scale systems.

## 37. Non-goals and constraints

The design intentionally avoids several traps:

- no full chromosome simulator;
- no requirement to simulate every remote creature continuously;
- no assumption that intelligence requires humanoid anatomy;
- no requirement that civilization requires swords or human-shaped armor;
- no automatic accumulation of only beneficial mutations;
- no guaranteed universal spell list;
- no ordinary firearms-driven technological endgame;
- no automatic loyalty from relatives;
- no requirement that the player become an empire-management cursor;
- no universal identical lifecycle or reproduction mechanic for all species.

## 38. Architectural implications for future planning

The implementation plan should preserve separate data models for:

- body plan;
- genome and inherited traits;
- individual creature state;
- personality and behavioral history;
- food preference/aversion;
- memory and knowledge;
- relationships;
- species definition;
- population state;
- faction state;
- lineage graph;
- nest/base state;
- world-zone state;
- simulation level of detail;
- future magic-law definitions;
- language/culture naming profile;
- semantic generated-name record with historical aliases;
- localization keys, locale templates, and grammar metadata;
- future legacy templates.

Species definitions must not be implemented as one hardcoded character class per possible hybrid. A creature should be assembled from a body plan plus modular biological traits and individual state.

The 0.1 implementation should prioritize testable, isolated systems and data-driven definitions so that traits, species, offspring rules, and future world content can be added without rewriting the core creature controller.

Localization and procedural naming must remain downstream of semantic game data: simulation code produces stable IDs and structured meaning, while locale-specific resources decide how that meaning is rendered to the player.
