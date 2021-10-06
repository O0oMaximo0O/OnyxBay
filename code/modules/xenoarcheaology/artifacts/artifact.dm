#define VISIBLE_TOGGLE TRUE
#define INVISIBLE_TOGGLE FALSE

/obj/machinery/artifact
	name = "alien artifact"
	desc = "A large alien device."
	icon = 'icons/obj/xenoarchaeology.dmi'
	icon_state = "ano00"
	var/icon_num = 0
	density = 1
	var/datum/artifact_effect/main_effect
	var/datum/artifact_effect/secondary_effect
	var/being_used = 0

/obj/machinery/artifact/New()
	..()

	var/effecttype = pick(subtypesof(/datum/artifact_effect))
	main_effect = new effecttype(src)

	if(prob(75))
		effecttype = pick(subtypesof(/datum/artifact_effect))
		secondary_effect = new effecttype(src)
		if(prob(75))
			secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)

	icon_num = rand(0, 11)

	icon_state = "ano[icon_num]0"
	if(icon_num == 7 || icon_num == 8)
		name = "large crystal"
		desc = pick("It shines faintly as it catches the light.",
		"It appears to have a faint inner glow.",
		"It seems to draw you inward as you look it at.",
		"Something twinkles faintly as you look at it.",
		"It's mesmerizing to behold.")
		if(prob(50))
			main_effect.trigger = TRIGGER_ENERGY
	else if(icon_num == 9)
		name = "alien computer"
		desc = "It is covered in strange markings."
		if(prob(75))
			main_effect.trigger = TRIGGER_TOUCH
	else if(icon_num == 10)
		desc = "A large alien device, there appear to be some kind of vents in the side."
		if(prob(50))
			main_effect.trigger = pick(TRIGGER_ENERGY, TRIGGER_HEAT, TRIGGER_COLD, TRIGGER_PLASMA, TRIGGER_OXY, TRIGGER_CO2, TRIGGER_NITRO)
	else if(icon_num == 11)
		name = "sealed alien pod"
		desc = "A strange alien device."
		if(prob(25))
			main_effect.trigger = pick(TRIGGER_WATER, TRIGGER_ACID, TRIGGER_VOLATILE, TRIGGER_TOXIN)

/obj/machinery/artifact/Destroy()
	QDEL_NULL(main_effect)
	QDEL_NULL(secondary_effect)
	. = ..()

/obj/machinery/artifact/Process()
	var/turf/L = loc
	if(!istype(L)) 	// We're inside a container or on null turf, either way stop processing effects
		return

	if(main_effect)
		main_effect.process()
	if(secondary_effect)
		secondary_effect.process()

	if(pulledby)
		Bumped(pulledby)

	var/triggers = 0
	if((main_effect.trigger | secondary_effect?.trigger) & TRIGGERS_ENVIROMENT)
		var/turf/T = get_turf(src)
		var/datum/gas_mixture/env = T.return_air()
		if(env)
			if(env.temperature < 225)
				triggers |= TRIGGER_COLD
			else if(env.temperature > 375)
				triggers |= TRIGGER_HEAT

			if(env.gas["plasma"] >= 10)
				triggers |= TRIGGER_PLASMA
			if(env.gas["oxygen"] >= 10)
				triggers |= TRIGGER_OXY
			if(env.gas["carbon_dioxide"] >= 10)
				triggers |= TRIGGER_CO2
			if(env.gas["nitrogen"] >= 10)
				triggers |= TRIGGER_NITRO
		if(min(1, T.get_lumcount()) > 0.33)
			triggers |= TRIGGER_LIGHT
		else
			triggers |= TRIGGER_DARK

	if((main_effect.trigger & triggers && !main_effect.activated) || (!(main_effect.trigger & triggers) && main_effect.activated))
		main_effect.ToggleActivate(VISIBLE_TOGGLE)
	if(secondary_effect && (secondary_effect.trigger & triggers && !secondary_effect.activated) || (!(secondary_effect.trigger & triggers) && secondary_effect.activated))
		secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)


/obj/machinery/artifact/attack_hand(mob/user as mob)
	if (get_dist(user, src) > 1)
		to_chat(user, "<span class='warning'>You can't reach \the [src] from here.</span>")
		return
	if(ishuman(user) && user:gloves)
		to_chat(user, "<b>You touch [src]</b> with your gloved hands, [pick("but nothing of note happens","but nothing happens","but nothing interesting happens","but you notice nothing different","but nothing seems to have happened")].")
		return

	src.add_fingerprint(user)

	if(main_effect.trigger & TRIGGER_TOUCH)
		to_chat(user, "<b>You touch [src].</b>")
		main_effect.ToggleActivate(VISIBLE_TOGGLE)
	else
		to_chat(user, "<b>You touch [src],</b> [pick("but nothing of note happens","but nothing happens","but nothing interesting happens","but you notice nothing different","but nothing seems to have happened")].")

	if(prob(25) && secondary_effect?.trigger & TRIGGER_TOUCH)
		secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)

	if(main_effect.effect & EFFECT_TOUCH && main_effect.activated)
		main_effect.DoEffectTouch(user)

	if(secondary_effect?.effect & EFFECT_TOUCH && secondary_effect?.activated)
		secondary_effect.DoEffectTouch(user)

/obj/machinery/artifact/attackby(obj/item/weapon/W as obj, mob/living/user as mob)
	var/triggers = 0

	if(istype(W, /obj/item/weapon/reagent_containers/))
		if(W.reagents.has_reagent(/datum/reagent/hydrazine, 1) || W.reagents.has_reagent(/datum/reagent/water, 1))
			triggers |= TRIGGER_WATER
		if(W.reagents.has_reagent(/datum/reagent/acid, 1) || W.reagents.has_reagent(/datum/reagent/acid/polyacid, 1) || W.reagents.has_reagent(/datum/reagent/diethylamine, 1))
			triggers |= TRIGGER_ACID
		if(W.reagents.has_reagent(/datum/reagent/toxin/plasma, 1) || W.reagents.has_reagent(/datum/reagent/thermite, 1))
			triggers |= TRIGGER_VOLATILE
		if(W.reagents.has_reagent(/datum/reagent/toxin, 1) || W.reagents.has_reagent(/datum/reagent/toxin/cyanide, 1) || W.reagents.has_reagent(/datum/reagent/toxin/amatoxin, 1) || W.reagents.has_reagent(/datum/reagent/ethanol/neurotoxin, 1))
			triggers |= TRIGGER_TOXIN
	else if(istype(W,/obj/item/weapon/melee/baton) && W:status ||\
			istype(W,/obj/item/weapon/melee/energy) ||\
			istype(W,/obj/item/weapon/melee/cultblade) ||\
			istype(W,/obj/item/weapon/card/emag) ||\
			istype(W,/obj/item/device/multitool))
		triggers |= TRIGGER_ENERGY
	else if (istype(W,/obj/item/weapon/flame) && W:lit ||\
			isWelder(W) && W:welding)
		triggers |= TRIGGER_HEAT)
	else
		..()
		if (main_effect.trigger & TRIGGER_FORCE && W.force >= 10)
			main_effect.ToggleActivate(VISIBLE_TOGGLE)
		if(secondary_effect?.trigger & TRIGGER_FORCE && prob(25))
			secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)
		return

	if(main_effect.trigger & triggers)
		main_effect.ToggleActivate(VISIBLE_TOGGLE)
	if(secondary_effect?.trigger & triggers && prob(25))
		secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)

/obj/machinery/artifact/Bumped(M as mob|obj)
	..()
	if(istype(M,/obj))
		var/obj/O = M
		if(O.throwforce >= 10)
			if(main_effect.trigger & TRIGGER_FORCE)
				main_effect.ToggleActivate(VISIBLE_TOGGLE)
			if(secondary_effect?.trigger & TRIGGER_FORCE && prob(25))
				secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)
	else if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if(!istype(H.gloves, /obj/item/clothing/gloves))
			var/warn = 0

			if (main_effect.trigger & TRIGGER_TOUCH && prob(50))
				main_effect.ToggleActivate(VISIBLE_TOGGLE)
				warn = 1
			if(secondary_effect?.trigger & TRIGGER_TOUCH && prob(25))
				secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)
				warn = 1

			if (main_effect.effect & EFFECT_TOUCH && main_effect.activated && prob(50))
				main_effect.DoEffectTouch(M)
				warn = 1
			if(secondary_effect?.effect & EFFECT_TOUCH && secondary_effect.activated && prob(50))
				secondary_effect.DoEffectTouch(M)
				warn = 1

			if(warn)
				to_chat(M, "<b>You accidentally touch [src].</b>")
	..()

/obj/machinery/artifact/bullet_act(obj/item/projectile/P)
	if(istype(P,/obj/item/projectile/bullet) ||\
		istype(P,/obj/item/projectile/hivebotbullet))
		if(main_effect.trigger & TRIGGER_FORCE)
			main_effect.ToggleActivate(VISIBLE_TOGGLE)
		if(secondary_effect?.trigger & TRIGGER_FORCE && prob(25))
			secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)

	else if(istype(P,/obj/item/projectile/beam) ||\
		istype(P,/obj/item/projectile/ion) ||\
		istype(P,/obj/item/projectile/energy))
		if(main_effect.trigger & TRIGGER_ENERGY)
			main_effect.ToggleActivate(VISIBLE_TOGGLE)
		if(secondary_effect?.trigger & TRIGGER_ENERGY && prob(25))
			secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)

/obj/machinery/artifact/ex_act(severity)
	switch(severity)
		if(1.0) qdel(src)
		if(2.0)
			if (prob(50))
				qdel(src)
			else
				if(main_effect.trigger & (TRIGGER_FORCE | TRIGGER_HEAT))
					main_effect.ToggleActivate(VISIBLE_TOGGLE)
				if(secondary_effect?.trigger & (TRIGGER_FORCE | TRIGGER_HEAT) && prob(25))
					secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)
		if(3.0)
			if (main_effect.trigger & (TRIGGER_FORCE | TRIGGER_HEAT))
				main_effect.ToggleActivate(VISIBLE_TOGGLE)
			if(secondary_effect?.trigger & (TRIGGER_FORCE | TRIGGER_HEAT) && prob(25))
				secondary_effect.ToggleActivate(INVISIBLE_TOGGLE)
	return

/obj/machinery/artifact/Move()
	..()
	if(main_effect)
		main_effect.UpdateMove()
	if(secondary_effect)
		secondary_effect.UpdateMove()

#undef VISIBLE_TOGGLE
#undef INVISIBLE_TOGGLE
