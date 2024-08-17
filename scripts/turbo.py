#!/usr/bin/python3

import sys
from gi.repository import Gio, GLib, GObject

proxy = None
loop = None

def on_changed_props(proxy, changed_props, invalidated_props):
    p = changed_props['ActiveProfile']
    print(p)
    f = open("/sys/devices/system/cpu/intel_pstate/no_turbo", "a")
    if (p == "balanced"):
        f.write("1")
    else:
        f.write("0")
    f.close()
    #loop.quit()

def main():
    loop = GLib.MainLoop()
    bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
    proxy = Gio.DBusProxy.new_sync(bus, Gio.DBusProxyFlags.NONE, None,
                                'net.hadess.PowerProfiles',
                                '/net/hadess/PowerProfiles',
                                'net.hadess.PowerProfiles', None)
    proxy.connect('g-properties-changed', on_changed_props)
    loop.run()

main()
