# Custom Game Menu Buttons 1.0.0 artwork

Approved supplied artwork: cyan sliders for the main addon, green sigil for ForeverAuras, red arrow for Reload UI.

Masters are byte-for-byte copies of the supplied originals. Exports preserve the entire artwork, including borders, and use centered transparent padding if needed. No recoloring or redraw.

`AddOns/` contains media only; these are not installable addon distributions. Copy each Media folder into its matching addon during implementation. Exact IconTexture metadata is recorded in manifest.json. Live addon-list rendering remains to be checked in the Forever client.

`exports/` contains 512px PNG page icons. `Icon-Preview.png` shows all three at 280, 64, 24 and 16px.

Rebuild with Python 3 and Pillow: `python3 tools/build_icons.py` from this directory. Asset licensing has not been independently established; retain the owner-supplied licensing information when publishing.
