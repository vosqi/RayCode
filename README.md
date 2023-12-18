RayCode https://create.roblox.com/marketplace/asset/15672482231/RayCode%3Fkeyword=&pageNumber=&pagePosition=

I started working on this plugin known as RayCode about 2 months ago as a simple but useful IDE/code-editor.

There’s builtin syntax-highlighting, that is fast and runs separately from the editor to avoid yielding.

https://github.com/vxsqi/RayCode/assets/74667208/edc605e7-9f3a-4c44-8a1b-079656e83c14

(boatbomber’s highlight module sample code: https://github.com/boatbomber/Highlighter)

Flexible Window Sizing

https://github.com/vxsqi/RayCode/assets/74667208/2610a231-31e0-44eb-ab08-fe29266a23b8

I’ve also implemented autocomplete which interprets different key types (e.g function → ()) and can be autocompleted via the tab key or clicking one of the keywords in the list. It also recognizes libraries and variables.

https://github.com/vxsqi/RayCode/assets/74667208/d3c1e5a0-4ef5-4b34-9670-adbb7894a0c7

Context-menu for clear navigation of actions and windows

https://github.com/vxsqi/RayCode/assets/74667208/06b7ce24-caaa-4773-a09b-f5584a2522ec

Preferences/Settings

https://github.com/vxsqi/RayCode/assets/74667208/d82b3bde-b7a6-4426-b395-5911c3e8f4d6

Independent Output Logging

https://github.com/vxsqi/RayCode/assets/74667208/0c4c9a52-18b8-47e6-9ff5-32f812a1244f

Saving

https://github.com/vxsqi/RayCode/assets/74667208/ca26854a-956d-4381-9377-65b3f795b19f

Formatting Code

https://github.com/vxsqi/RayCode/assets/74667208/353389ea-a86f-437d-a030-43f7ea64d587

But why?
I wanted to make something that was easy, portable and useful; you just whip it up and tada - it works. I found other plugins like InCommand which were lacking in useful settings like color config, autofill, etc (although I know it’s sole purpose was to be simple). There’s no practical use of this over Roblox’s script editor which includes a much more intelligent LSP.

Any future plans?
I plan to integrate some sort of VSC-like feature that allows version control, let me know any ideas!

Issues?
This is a huge plugin and right now there are too many issues for me to maintain, find and fix.

Although tabbing does work, pasting code will not auto-format it as it’s regex is reserved for autofill (input is a lot more restrictive within plugins). It’s mostly just visual bugs which don’t affect the actual functionality of the plugin as of now, but I do still hope to find more.

I’m considering letting someone else alot more experienced than me to takeover the plugin as I plan to completely remake this plugin into something alot more simple like InCommand with the same features (autofill, execute, syntax-highlighting, saving scripts, etc).

Use Cases

Testing code for client or serversided in real-time (both playtesting and whatnot)
Keeping a directory of saved scripts per project without having to make messy folders and search for it
Keep logs independent from the output which can reduce messy error loggings and fill it
For now, the plugin is not for sale.

Appreciating all feedback!
