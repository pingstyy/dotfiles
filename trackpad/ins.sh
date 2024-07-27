{#try
  sudo vim /etc/X11/xorg.conf.d/30-touchpad.conf

  &&
} || {
# else
  sudo nvim /etc/X11/xorg.conf.d/30-touchpad.conf
}
