"""Deterministic StandardMaterial3D delivery state resources (sRGB palette)."""
from pathlib import Path
out = Path('godot/assets/models/stations/order_stand')
colors = ['1D3557','D2473F','3F7CC8','E8C23A','4FA05A']
for i, h in enumerate(colors):
    c = ', '.join(f'{int(h[j:j+2],16)/255:.9f}' for j in (0,2,4)) + ', 1'
    name = 'delivery_zone_off' if i == 0 else f'delivery_zone_on_{i}'
    text = f'[gd_resource type="StandardMaterial3D" format=3]\n\n[resource]\nresource_name = "{name}"\nalbedo_color = Color({c})\nroughness = 0.9\n'
    if i:
        text += f'emission_enabled = true\nemission = Color({c})\nemission_energy_multiplier = 0.45\n'
    (out / (name+'.tres')).write_text(text)
