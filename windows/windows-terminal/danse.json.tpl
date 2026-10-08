{
  "$help": "Windows Terminal fragment from the dotfiles checkout (windows/windows-terminal). Adds the danse scheme and applies it to the Arch WSL profile; setup.ps1 fills in that profile's GUID from settings.json. Every hex is a palette colour; test_palette.bats asserts it. Mapping mirrors .config/ghostty/themes/danse.",
  "schemes": [
    {
      "name": "danse",
      "background": "#21252b",
      "foreground": "#abb2bf",
      "cursorColor": "#61afef",
      "selectionBackground": "#3e4451",
      "black": "#21252b",
      "red": "#e06a51",
      "green": "#98c379",
      "yellow": "#e5c07b",
      "blue": "#61afef",
      "purple": "#c678dd",
      "cyan": "#56b6c2",
      "white": "#abb2bf",
      "brightBlack": "#5c6370",
      "brightRed": "#e06a51",
      "brightGreen": "#98c379",
      "brightYellow": "#e5c07b",
      "brightBlue": "#61afef",
      "brightPurple": "#c678dd",
      "brightCyan": "#56b6c2",
      "brightWhite": "#abb2bf"
    }
  ],
  "profiles": [
    {
      "updates": "{{ARCH_PROFILE_GUID}}",
      "colorScheme": "danse",
      "font": {
        "face": "JetBrainsMono Nerd Font",
        "size": 12
      }
    }
  ]
}
