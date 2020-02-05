# Arch-Stuff
 Arch scripts I made for personal use
 
**for nemo:**
- session and startup > nemo-desktop
-  desktop > icons > icon type: none

``` 
    gsettings set org.nemo.desktop ignored-desktop-handlers ["'xfdesktop'"]
    gsettings set org.nemo.desktop font 'Cantarell Regular 10'
    gsettings set org.nemo.preferences size-prefixes 'base-2'
```

**for xfce power manager:**

    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-power-key -n -t bool -s true
    xfconf-query -c xfce4-power-manager -p /xfce4-power-manager/logind-handle-lid-switch -n -t bool -s true