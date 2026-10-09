from pathlib import Path
import re
import shutil
import subprocess

workspace = Path(__file__).resolve().parent
gradle_source = Path('C:/Users/ASUS/.gradle').resolve()
destination = workspace / '.android-build-cache/gradle-home'
assert destination.resolve().is_relative_to(workspace)

def windows_path(path):
    return '\\\\?\\' + str(path.resolve())

# Stop only the most recent Gradle 9.3 daemon started for this project.
logs = list((gradle_source / 'daemon/9.3.1').glob('daemon-*.out.log'))
if logs:
    latest = max(logs, key=lambda p: p.stat().st_mtime)
    contents = latest.read_text(errors='replace')
    if str(workspace / 'mobile/android') in contents:
        pid = re.fullmatch(r'daemon-(\d+)\.out\.log', latest.name).group(1)
        subprocess.run(['taskkill', '/PID', pid, '/T', '/F'], check=False)

# Preserve the downloaded Gradle documentation on D:, freeing C: space.
distribution = gradle_source / 'wrapper/dists/gradle-9.3.1-all/9ot9r568e8zfvvd4mn8rbu1j0/gradle-9.3.1'
for name in ['docs', 'src']:
    source = (distribution / name).resolve()
    target = (workspace / '.android-build-cache' / ('gradle-' + name)).resolve()
    assert source.is_relative_to(gradle_source / 'wrapper/dists/gradle-9.3.1-all')
    assert target.is_relative_to(workspace)
    if source.exists():
        shutil.copytree(windows_path(source), windows_path(target), dirs_exist_ok=True)
        # Both absolute targets were checked above; docs are preserved on D:.
        shutil.rmtree(windows_path(source))

# Copy caches; leave the user's original cache and Gradle settings intact.
for name in ['caches', 'wrapper', 'native']:
    source = gradle_source / name
    target = destination / name
    if source.exists():
        print('Copying Gradle ' + name + ' to D:', flush=True)
        shutil.copytree(windows_path(source), windows_path(target), dirs_exist_ok=True, ignore=shutil.ignore_patterns('*.lock', '*.lck'))
(workspace / '.android-build-cache/tmp').mkdir(parents=True, exist_ok=True)
print('Project Gradle cache prepared on D:. C: free bytes:', shutil.disk_usage('C:/').free)
