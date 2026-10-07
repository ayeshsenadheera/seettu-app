from pathlib import Path
import os
import subprocess

root = Path(__file__).resolve().parent
avd_home = root / '.android-build-cache/avd'
device_dir = avd_home / 'SeettuAndroid.avd'
device_dir.mkdir(parents=True, exist_ok=True)
source = Path('C:/Users/ASUS/.android/avd/Pixel_6_API_36.avd/config.ini')
config = dict(line.split('=', 1) for line in source.read_text().splitlines() if '=' in line)
config.update({'AvdId': 'SeettuAndroid', 'avd.ini.displayname': 'Seettu Android Preview',
    'disk.dataPartition.size': '8G', 'fastboot.forceColdBoot': 'yes', 'fastboot.forceFastBoot': 'no',
    'hw.sdCard': 'no', 'hw.ramSize': '2048'})
config.pop('sdcard.size', None)
(device_dir / 'config.ini').write_text('\n'.join(f'{key}={value}' for key, value in config.items()) + '\n')
(avd_home / 'SeettuAndroid.ini').write_text(f'avd.ini.encoding=UTF-8\npath={device_dir}\ntarget=android-36\n')
sdk = Path('C:/Users/ASUS/AppData/Local/Android/sdk')
env = dict(os.environ, ANDROID_AVD_HOME=str(avd_home), ANDROID_SDK_ROOT=str(sdk),
    TEMP=str(root / '.android-build-cache/tmp'), TMP=str(root / '.android-build-cache/tmp'))
with (avd_home / 'emulator.log').open('w') as log:
    process = subprocess.Popen([str(sdk / 'emulator/emulator.exe'), '-avd', 'SeettuAndroid',
        '-port', '5556', '-no-snapshot', '-no-boot-anim', '-gpu', 'swiftshader_indirect', '-feature', '-Vulkan'], env=env,
        stdin=subprocess.DEVNULL, stdout=log, stderr=subprocess.STDOUT,
        creationflags=subprocess.DETACHED_PROCESS)
print('Started Seettu Android Preview, PID', process.pid, 'device emulator-5556')
