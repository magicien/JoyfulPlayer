from __future__ import unicode_literals

import biplist
import os.path

app = defines.get('app', './dmg/JoyfulPlayer.app')
appname = os.path.basename(app)

# Basics

format = defines.get('format', 'UDZO')
size = defines.get('size', None)
files = [ app ]

icon_locations = {
    appname:        (160, 160),
}

# Window configuration

show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
sidebar_width = 180

window_rect = ((322, 331), (320, 362))

defaullt_view = 'icon_view'

# Icon view configuration

arrange_by = None
grid_offset = (0, 0)
grid_spacing = 100
scrolll_position = (0, 0)
label_pos = 'bottom'
text_size = 12
icon_size = 164

