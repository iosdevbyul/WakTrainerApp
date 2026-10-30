#!/usr/bin/env python3
"""Validate all app/widget target memberships and ActivityKit source image limits."""
import json
from pathlib import Path
import plistlib
import struct
import subprocess

root = Path(__file__).resolve().parents[1]
project = json.loads(subprocess.check_output([
    'plutil', '-convert', 'json', '-o', '-', str(root / 'WakTrainer.xcodeproj/project.pbxproj')
]))['objects']
targets = {v['name']: v for v in project.values() if v.get('isa') == 'PBXNativeTarget'}
for app_name, widget_name in [('WakTrainer', 'WakTrainerWorkoutWidget'),
                              ('WakTrainerDemo', 'WakTrainerDemoWidget'),
                              ('WakTrainerDeviceTest', 'WakTrainerDeviceTestWidget')]:
    app, widget = targets[app_name], targets[widget_name]
    for target, folder in [(app, 'WakTrainer'), (widget, 'WakTrainerWorkoutWidget')]:
        groups = [project[g] for g in target['fileSystemSynchronizedGroups']]
        group = next(g for g in groups if g['path'] == folder)
        assert not group.get('exceptions'), f'{target["name"]}: review asset membership exceptions'
        assert any(project[p]['isa'] == 'PBXResourcesBuildPhase' for p in target['buildPhases'])
    for config in ('Debug', 'Release'):
        def settings(target):
            return next(project[c]['buildSettings'] for c in
                        project[target['buildConfigurationList']]['buildConfigurations']
                        if project[c]['name'] == config)
        a, w = settings(app), settings(widget)
        assert a['ASSETCATALOG_COMPILER_APPICON_NAME'] == 'AppIcon'
        assert a['INFOPLIST_KEY_NSSupportsLiveActivities'] == 'YES'
        assert w['PRODUCT_BUNDLE_IDENTIFIER'].startswith(a['PRODUCT_BUNDLE_IDENTIFIER'] + '.')
        info = plistlib.loads((root / w['INFOPLIST_FILE']).read_bytes())
        assert info['NSExtension']['NSExtensionPointIdentifier'] == 'com.apple.widgetkit-extension'
    assert any(project[d]['target'] == next(k for k, v in project.items() if v is widget)
               for d in app['dependencies']), f'{app_name}: widget dependency missing'
    embed = [project[f] for p in app['buildPhases'] if project[p]['isa'] == 'PBXCopyFilesBuildPhase'
             for f in project[p]['files']]
    assert any(f.get('fileRef') == widget['productReference'] for f in embed)

catalog = root / 'WakTrainerWorkoutWidget/Assets.xcassets/WakTrainerAppLogo.imageset'
asset = json.loads((catalog / 'Contents.json').read_text())
assert asset['properties']['template-rendering-intent'] == 'original'
assert {i['scale'] for i in asset['images']} == {'1x', '2x', '3x'}
for image in asset['images']:
    data = (catalog / image['filename']).read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    size = struct.unpack('>II', data[16:24])
    scale = int(image['scale'][0])
    assert size == (24 * scale, 24 * scale), f'{image["filename"]}: {size}'
    assert max(size) / scale <= 36.67  # smallest documented minimal presentation dimension

app_icon = root / 'WakTrainer/Assets.xcassets/AppIcon.appiconset'
for image in json.loads((app_icon / 'Contents.json').read_text())['images']:
    assert (app_icon / image['filename']).is_file()
print('Live Activity branding configuration passed: production, Demo, DeviceTest; Debug + Release; 24 pt logo at 1x/2x/3x.')
