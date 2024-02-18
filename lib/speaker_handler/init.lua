local SpeakerHandler = {
	_LoopedSounds = {},
	_ChatCooldowns = {}, -- Cooldowns of Speaker:Chat
	_SoundCooldowns = {}, -- Sounds played by SpeakerHandler.PlaySound
	DefaultSpeaker = nil,
}

function SpeakerHandler.Chat(text, cooldownTime, speaker)
	speaker = speaker or SpeakerHandler.DefaultSpeaker or error("[SpeakerHandler.Chat]: No speaker provided")

	if SpeakerHandler._ChatCooldowns[speaker.GUID..text] then
		return
	end

	speaker:Chat(text)

	if not cooldownTime then
		return
	end

	SpeakerHandler._ChatCooldowns[speaker.GUID..text] = true
	task.delay(cooldownTime, function()
		SpeakerHandler._ChatCooldowns[speaker.GUID..text] = nil
	end)
end

function SpeakerHandler.PlaySound(id, pitch, cooldownTime, speaker)
	speaker = speaker or SpeakerHandler.DefaultSpeaker or error("[SpeakerHandler.PlaySound]: No speaker provided")
	id = tonumber(id)
	pitch = tonumber(pitch) or 1

	if SpeakerHandler._SoundCooldowns[speaker.GUID..id] then
		return
	end
	
	if SpeakerHandler._LoopedSounds[speaker.GUID] then
		SpeakerHandler.RemoveSpeakerFromLoop(speaker)
	end

	speaker:Configure({Audio = id, Pitch = pitch})
	speaker:Trigger()

	if cooldownTime then
		SpeakerHandler._SoundCooldowns[speaker.GUID..id] = true

		task.delay(cooldownTime, function()
			SpeakerHandler._SoundCooldowns[speaker.GUID..id] = nil
		end)
	end
end

function SpeakerHandler.LoopSound(id, soundLength, pitch, speaker)
	speaker = speaker or SpeakerHandler.DefaultSpeaker or error("[SpeakerHandler.LoopSound]: No speaker provided")
	id = tonumber(id)
	pitch = tonumber(pitch) or 1
	
	if not soundLength then
		error("[SpeakerHandler.LoopSound]: The length of the sound must be defined")
	end
	
	if SpeakerHandler._LoopedSounds[speaker.GUID] then
		SpeakerHandler.RemoveSpeakerFromLoop(speaker)
	end
	
	speaker:Configure({Audio = id, Pitch = pitch})
	
	SpeakerHandler._LoopedSounds[speaker.GUID] = {
		Speaker = speaker,
		Length = soundLength / pitch,
		TimePlayed = tick()
	}
	
	speaker:Trigger()
	return true
end

function SpeakerHandler.RemoveSpeakerFromLoop(speaker)
	if not SpeakerHandler._LoopedSounds[speaker.GUID] then
		return
	end
	
	speaker:Configure({Audio = 0, Pitch = 1})
	speaker:Trigger()
	SpeakerHandler._LoopedSounds[speaker.GUID] = nil
end

function SpeakerHandler:UpdateSoundLoop(dt) -- Triggers any speakers if it's time for them to be triggered
	dt = dt or 0
	
	for _, info in pairs(SpeakerHandler._LoopedSounds) do
		local currentTime = tick() - dt
		local timePlayed = currentTime - info.TimePlayed

		if timePlayed >= info.Length then
			info.TimePlayed = tick()
			info.Speaker:Trigger()
		end
	end
end

function SpeakerHandler:StartSoundLoop() -- If you use this, you HAVE to put it at the end of your code.
	
	while true do
		local dt = task.wait()
		SpeakerHandler:UpdateSoundLoop(dt)
	end
end

function SpeakerHandler.GetLoopInfo(speaker): { Length: number, TimePlayed: number }
	if not speaker then
		error("[SpeakerHandler.GetLoopInfo]: No speaker provided")
	end
	
	local info = SpeakerHandler._LoopedSounds[speaker.GUID]
	
	if not info then
		return
	end
	
	return {
		Length = info.Length,
		TimePlayed = tick() - info.TimePlayed
	}
end

function SpeakerHandler.CreateSound(config: { Id: number, Pitch: number, Length: number, Speaker: any, RepeatCount: number, RepeatDelay: number } ) -- Psuedo sound object, kinda bad
	config.Pitch = config.Pitch or 1
	config.RepeatCount = config.RepeatCount or 1
	config.RepeatDelay = config.RepeatDelay or 0
	
	local sound = {
		ClassName = "SpeakerHandler.Sound",
		Id = config.Id,
		Pitch = config.Pitch,
		_Speaker = config.Speaker or SpeakerHandler.DefaultSpeaker or error("[SpeakerHandler.CreateSound]: A speaker must be provided"),
		_OnCooldown = false, -- For sound cooldowns
		_Looped = false
	}
	
	if config.Length then
		sound.Length = config.Length / config.Pitch
	end
	
	function sound:Play(cooldownSeconds)
		if sound._OnCooldown then
			return
		end
		
		if sound._RepeatThread then
			coroutine.close(sound._RepeatThread)
			sound._RepeatThread = nil
		end
		
		sound._Speaker:Configure({Audio = sound.Id, Pitch = sound.Pitch})
		
		sound._RepeatThread = task.spawn(function()
			for i = 1, config.RepeatCount do
				sound._Speaker:Trigger()
				task.wait( (sound.Length or 0) + config.RepeatDelay )
			end
		end)
		
		if not cooldownSeconds then
			return
		end
		
		sound._OnCooldown = true
		task.delay(cooldownSeconds, function()
			sound._OnCooldown = false
		end)
	end
	
	function sound:Stop()
		sound._Speaker:Configure({Audio = 0, Pitch = 1})
		sound._Speaker:Trigger()
		
		if sound._RepeatThread then
			coroutine.close(sound._RepeatThread)
			sound._RepeatThread = nil
		end
		
		sound._OnCooldown = false
		SpeakerHandler.RemoveSpeakerFromLoop(sound._Speaker)
	end
	
	function sound:Loop()
		if not sound.Length then
			error("[SpeakerHandler.Sound]: Sound must have a length to be looped")
		end
		
		sound._Looped = true
		SpeakerHandler.LoopSound(sound.Id, sound.Length, sound.Pitch, sound._Speaker)
	end
	
	function sound:Destroy()
		if sound._Looped then
			SpeakerHandler.RemoveSpeakerFromLoop(sound._Speaker)
		end
		
		table.clear(sound)
	end
	
	return sound
end

return SpeakerHandler
