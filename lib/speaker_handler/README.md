## Speaker Handler

This adds some useful things to speakers I think.

```lua
local Speaker = GetPartFromPort(1, "Speaker")

SpeakerHandler.DefaultSpeaker = Speaker -- If no speaker is provided, it will be defaulted to this speaker

SpeakerHandler.Chat("Hello", 2, Speaker) -- Speaker cannot chat that message for 2 seconds

SpeakerHandler.PlaySound(12345, 1.5, 2, Speaker) -- Speaker plays sound at 1.5 pitch and cannot play it again for 2 seconds

SpeakerHandler.LoopSound(12345, 20, 1.5, Speaker) -- Speaker plays the sound, but does not loop unless the speaker update loop is started (uhh the 20 is the length of the sound)

SpeakerHandler.RemoveSpeakerFromLoop(Speaker) -- Removes speaker from the update loop and stops playing

SpeakerHandler:StartSoundLoop() -- Starts the while true loop that updates all of the looped speakers. Yields the thread

local soundObject = SpeakerHandler.CreateSound({
    Id = 12345,
    Length = 20, -- Sound length seconds,
    Pitch = 3
})

soundObject:Play(12) -- Plays sound with a cooldown of 12 seconds where it can't be played
soundObject:Stop() -- Stops sound from playing
soundObject:Loop() -- Adds sound to the update sound loop
soundObject:Destroy() -- Unloops and destroys the sound
```
