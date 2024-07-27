Section "InputClass"
  Identifier "touchpad"
  Driver "libinput"
  MatchIsTouchpad "on"
  Option "Tapping" "on"
  Option "TappingButtonMap" "lmr"
EndSection

# 
  # Option "TappingButtonMap" "lmr"
  # Double tap -> mouse middle scroll button click
  # tripple tap -> Right click
  #
  #
  # Other Option
  # "lmr" , "lrm"
  # for 
  # "lrm" -> 1 tap - left Click , 2 tap - Right click, 3 tap - Middle Click
