util.register_class("ents.MonsterZombieComponent", BaseEntityComponent)
local Component = ents.MonsterZombieComponent

Animation.ACT_DIE_HEADSHOT = Animation.RegisterActivity("ACT_DIE_HEADSHOT")

Animation.EVENT_NPC_BODYDROP_LIGHT = Animation.RegisterEvent("EVENT_NPC_BODYDROP_LIGHT")
Animation.EVENT_NPC_1 = Animation.RegisterEvent("EVENT_NPC_1")
Animation.EVENT_NPC_2 = Animation.RegisterEvent("EVENT_NPC_2")
Animation.EVENT_NPC_3 = Animation.RegisterEvent("EVENT_NPC_3")
Animation.EVENT_SCRIPT_SOUND = Animation.RegisterEvent("EVENT_SCRIPT_SOUND")

game.load_sound_scripts("fx_npc_zombie.udm", true)
local cvHealth = console.register_variable(
	"sk_zombie_health",
	udm.TYPE_UINT32,
	100,
	bit.bor(console.FLAG_BIT_ARCHIVE, console.FLAG_BIT_REPLICATED),
	"Specifies the zombie's default health."
)

function Component:__init()
	BaseEntityComponent.__init(self)
end

function Component:Initialize()
	local ent = self:GetEntity()

	self:AddEntityComponent(ents.COMPONENT_CHARACTER, "InitializeCharacter")
	self:AddEntityComponent(ents.COMPONENT_AI, "InitializeAI")
	self:AddEntityComponent(ents.COMPONENT_HEALTH, "InitializeHealth")
	self:AddEntityComponent(ents.COMPONENT_TRANSFORM, "InitializeTransform")
	self:AddEntityComponent(ents.COMPONENT_PHYSICS, "InitializePhysics")
	self:AddEntityComponent(ents.COMPONENT_MODEL, "InitializeModel")
	self:AddEntityComponent(ents.COMPONENT_DAMAGEABLE)
	self:AddEntityComponent(ents.COMPONENT_SOUND_EMITTER)
	self:AddEntityComponent(ents.COMPONENT_ANIMATED, "InitializeAnimated")

	if SERVER == true then
		self:BindEvent(ents.AIComponent.EVENT_SELECT_SCHEDULE, "SelectSchedule")
		self:BindEvent(ents.AIComponent.EVENT_SELECT_CONTROLLER_SCHEDULE, "SelectControllerSchedule")
		self:BindEvent(ents.AIComponent.EVENT_ON_PRIMARY_TARGET_CHANGED, "OnPrimaryTargetChanged")
		self:BindEvent(ents.AIComponent.EVENT_ON_NPC_STATE_CHANGED, "OnNPCStateChanged")
		self:BindEvent(ents.AIComponent.EVENT_ON_TARGET_ACQUIRED, "OnTargetAcquired")

		self.m_tNextIdle = 0
	end
	self:BindEvent(ents.AnimatedComponent.EVENT_HANDLE_ANIMATION_EVENT, "HandleAnimationEvent")
	self:BindEvent(ents.CharacterComponent.EVENT_PLAY_FOOTSTEP_SOUND, "PlayFootStepSound")

	if SERVER == true then
		self:InitializeSchedules()
	end
end

function Component:InitializeAnimated(component)
	component:BindAnimationEvent(Animation.EVENT_SCRIPT_SOUND, self, "PlayScriptSound")

	if SERVER == true then
		component:BindAnimationEvent(Animation.EVENT_NPC_1, function() -- First swipe of first melee attack
			self:DealMeleeDamage(EulerAngles(-8, -52, -12))
		end)
		component:BindAnimationEvent(Animation.EVENT_NPC_2, function() -- Second swipe of first melee attack
			self:DealMeleeDamage(EulerAngles(-8, 52, -12))
		end)
		component:BindAnimationEvent(Animation.EVENT_NPC_3, function() -- Second melee attack (Only has one swipe)
			self:DealMeleeDamage(EulerAngles(60, 0, 0))
		end)
		component:BindAnimationEvent(Animation.EVENT_NPC_BODYDROP_LIGHT, self, "DropBody")
	end
end

function Component:PlayScriptSound(snd)
	local animComponent = self:GetEntity():GetComponent(ents.COMPONENT_ANIMATED)
	if snd == nil or animComponent == nil then
		return
	end
	local leftFoot
	if snd == "NPC.StepLeftWalk" or snd == "NPC.StepLeftRun" then
		leftFoot = true
	elseif snd == "NPC.StepRightWalk" or snd == "NPC.StepRightRun" then
		leftFoot = false
	end
	if leftFoot ~= nil then
		local type = (leftFoot == true) and Animation.EVENT_FOOTSTEP_LEFT or Animation.EVENT_FOOTSTEP_RIGHT
		animComponent:InjectAnimationEvent(type)
	end
end

function Component:InitializeAI(component)
	if SERVER then
		component:SetHearingStrength(0.6) -- Use 0.0 to disable the NPCs ability to hear, 1.0 means perfect hearing
		component:SetNPCState(ai.NPC_STATE_IDLE)
	end
	component:SetMoveSpeed("walk", 50.0) -- We don't use animation movement, so we have to specify a constant movement speed here
end

function Component:InitializeHealth(component)
	component:SetHealth(cvHealth:GetInt()) -- Grab the current value for the console command we've created earlier
end

function Component:InitializeTransform(component)
	component:SetScale(math.randomf(0.9, 1.1)) -- Give our NPC a random scale (It will sometimes spawn slightly smaller, sometimes larger than normal)
end

function Component:OnEntitySpawn()
	local physComponent = self:GetEntity():GetComponent(ents.COMPONENT_PHYSICS)
	if physComponent ~= nil then
		physComponent:SetCollisionBounds(Vector(-16, 0, -16), Vector(16, 72, 16)) -- Our collision bounds in units (Width, length = 16 and height = 72)
	end
	if CLIENT or physComponent == nil then
		return
	end
	physComponent:InitializePhysics(phys.TYPE_CAPSULECONTROLLER) -- Initialize our physics as a capsule. You can use phys.TYPE_BOXCONTROLLER to use a box-shape instead (Note: box-shapes are buggy at the time of this writing (2017-01-01) and should be avoided
end

function Component:InitializePhysics(component)
	if CLIENT == true then
		return
	end -- The following aren't needed clientside
	component:SetMoveType(ents.PhysicsComponent.MOVETYPE_WALK) -- Our NPC is ground-based
end

function Component:PlayFootStepSound(footType, surfaceMaterial, moveScale)
	local sndEmitterComponent = self:GetEntity():GetComponent(ents.COMPONENT_SOUND_EMITTER)
	if sndEmitterComponent ~= nil then
		local sndInfo = ents.SoundEmitterComponent.SoundInfo(1.0 * moveScale, 1.0)
		sndInfo.transmit = false
		sndEmitterComponent:EmitSound(
			(footType == ents.CharacterComponent.FOOT_LEFT) and "npc_zombie.walk_step_left"
				or "npc_zombie.walk_step_right",
			sound.TYPE_EFFECT,
			sndInfo
		)
	end
	return util.EVENT_REPLY_HANDLED -- Overwrite default footstep sound
end
ents.COMPONENT_MONSTER_ZOMBIE =
	ents.register_component("monster_zombie", Component, ents.EntityComponent.FREGISTER_BIT_NETWORKED)
