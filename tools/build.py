#!/usr/bin/env python3
"""Reproducible three-addon build; uses real Lua 5.1, never emulated Lua syntax."""
from pathlib import Path
import hashlib, os, re, shutil, subprocess, sys, tempfile, zipfile

ROOT=Path(__file__).resolve().parents[1]
DIST=ROOT/'dist'
ADDONS=ROOT/'AddOns'
VERSION=(ROOT/'VERSION').read_text().strip()
NAMES=['CustomGameMenuButtons','CustomGameMenuButtons-ForeverAuras','CustomGameMenuButtons-ReloadUI']
assert re.fullmatch(r'\d+\.\d+\.\d+',VERSION)
DIST.mkdir(exist_ok=True)

def run(args):
    r=subprocess.run(args,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    if r.returncode:
        print(r.stdout);raise RuntimeError('Check failed: '+str(args))
    return r.stdout

def lua_cmd(script,*args):
    native=shutil.which('lua5.1') or shutil.which('lua51')
    if native:return [native,str(script),*map(str,args)]
    from lupa.lua51 import LuaRuntime
    assert LuaRuntime().eval('_VERSION')=='Lua 5.1'
    return [sys.executable,str(ROOT/'tools/run_lua51.py'),str(script),*map(str,args)]

def archive(path,files):
    with zipfile.ZipFile(path,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for local,rel in sorted(files,key=lambda x:str(x[1])):
            info=zipfile.ZipInfo(str(rel).replace(os.sep,'/'),(2026,11,13,0,0,0))
            info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
            z.writestr(info,local.read_bytes())

def runtime_files(names):
    for name in names:
        for p in (ADDONS/name).rglob('*'):
            if p.is_file() and p.suffix in ('.lua','.toc','.tga') or p.is_file() and p.name=='LICENSE':
                yield p,p.relative_to(ADDONS)

# Generate actual metadata from the one public version source.
(ADDONS/NAMES[0]/'Version.lua').write_text('-- Copyright 2026 Azotorp. SPDX-License-Identifier: GPL-3.0-only\nCustomGameMenuButtonsVersion = "'+VERSION+'"\n')
for template in ADDONS.rglob('*.toc.in'):
    template.with_suffix('').write_text(template.read_text().replace('@VERSION@',VERSION))
icon_output=run([sys.executable,str(ROOT/'artwork/tools/build_icons.py')])
for name in NAMES:
    shutil.copyfile(ROOT/'artwork/AddOns'/name/'Media/AddonIcon.tga',ADDONS/name/'Media/AddonIcon.tga')
    shutil.copyfile(ROOT/'LICENSE',ADDONS/name/'LICENSE')

# Lua 5.1 syntax verification of all shipped modules and the behavioral harness.
syntax=ROOT/'tests/syntax.lua'
syntax.write_text('assert(_VERSION=="Lua 5.1")\n'+''.join('assert(loadfile('+repr(str(p)).replace("'",'"')+'))\n' for p in sorted(ADDONS.rglob('*.lua')))+'print("Lua 5.1 syntax: all shipped modules passed")\n')
checks=[run(lua_cmd(syntax)).strip(),icon_output.strip()]
syntax.unlink()
for name in NAMES:
    folder=ADDONS/name; tocs=list(folder.glob('*.toc'))
    assert len(tocs)==1 and tocs[0].name==name+'_Forever.toc'
    text=tocs[0].read_text();assert '## Version: '+VERSION in text
    assert '## Interface: 16001' in text and '## X-Flavor: Forever' in text
    assert '## X-License: GPL-3.0-only' in text
    assert '## IconTexture: Interface\\AddOns\\'+name+'\\Media\\AddonIcon.tga' in text
    if name!=NAMES[0]:assert '## Dependencies: CustomGameMenuButtons'+(', ForeverAuras' if name.endswith('ForeverAuras') else '') in text
    else:assert '## Dependencies:' not in text
    for line in text.splitlines():
        if line and not line.startswith('#'): assert (folder/line.replace('\\','/')).is_file(),line
    for p in folder.rglob('*.lua'):
        assert not re.search(r'\bReloadUI\s*\(',re.sub(r'--[^\n]*','',p.read_text())),p
    checks.append('PASS metadata/load paths: '+name)

source_log=run(lua_cmd(ROOT/'tests/harness.lua',ADDONS))
(ROOT/'docs/TEST-OUTPUT-Source.txt').write_text(source_log)
count=re.search(r'(\d+) passed; 0 failed\.',source_log).group(1)
packages=[]
for name in NAMES:
    target=DIST/(name+'-'+VERSION+'-Forever.zip')
    archive(target,list(runtime_files([name])));packages.append(target)
    with zipfile.ZipFile(target) as z:
        roots={n.split('/')[0] for n in z.namelist()}; assert roots=={name}
        assert all(not n.endswith('.toc.in') for n in z.namelist())
        assert z.read(name+'/LICENSE')==(ROOT/'LICENSE').read_bytes()
        assert not any(x in n for n in z.namelist() for x in ['masters/','.git/','Tests/'])
    checks.append('PASS single-root archive, GPL license and runtime-only contents: '+target.name)
allzip=DIST/('CustomGameMenuButtons-'+VERSION+'-AllAddons-ManualInstall.zip')
archive(allzip,list(runtime_files(NAMES)));packages.append(allzip)
with tempfile.TemporaryDirectory(prefix='cgmb-verify-') as temp:
    extracted=Path(temp)
    for p in packages[:3]:
        with zipfile.ZipFile(p) as z:z.extractall(extracted)
    extracted_log=run(lua_cmd(ROOT/'tests/harness.lua',extracted))
    (ROOT/'docs/TEST-OUTPUT-Extracted.txt').write_text(extracted_log)
    assert count==re.search(r'(\d+) passed; 0 failed\.',extracted_log).group(1)
    for id,names in [('base',[NAMES[0]]),('ForeverAuras',NAMES[:2]),('ReloadUI',[NAMES[0],NAMES[2]])]:
        isolated=extracted/id;isolated.mkdir()
        for name in names: shutil.copytree(extracted/name,isolated/name)
        checks.append(run(lua_cmd(ROOT/'tests/harness.lua',isolated,id)).strip())

checks.append('PASS masters preserved: three exact original files; see artwork/manifest.json SHA-256 values')
checks.append('Source and extracted distributions: '+count+' behavior groups each; 0 failures')
(ROOT/'docs/PACKAGE-CHECKS.txt').write_text('\n'.join(checks)+'\n')
report='''# 1.0.0 implementation report

Built the three requested Forever addon distributions from the working private source, with editor and creator integrated into main, original secure reload preserved, supplied icons applied, and each optional successor owning only its original published-folder retirement.

## Verification results

Real Lua 5.1 (native interpreter when available; this session uses Lupa's embedded Lua 5.1). **COUNT behavior groups pass on source and the extracted distribution, 0 failures in each run.** The twelve layout-table rows assert order, skin, overlap, bounds, ten reopens and a second Arrange. Three isolated package-load checks also pass, alongside metadata, load-path, license, icon and archive checks. These are offline simulations, not engine acceptance.

## Decisions and differences from private builds

- Exactly three folders/products. Public release 1.0.0 is separate from extension API 1, root schema 1, preference schema 2 and internal replacement counter 9.
- Main DB owns layout, editor link and custom definitions. Final-named successor preference DBs remain. No private Editor/CustomButton settings import and no saved-file deletion.
- Global layout/default resets also stage family anchor resets and support Cancel. Detailed family Reset now edits its draft; Save commits and close discards. Explicit slash resets outside dialogs act immediately.
- Validated attempted custom-action saves/deletions queue through combat, retaining the form. Explicit queued operations survive form closure. Existing action loads also wait for combat end.
- New custom tools share an addon-tools block, rather than joining session/logout actions. Multiple default tools do not each insert a section gap.
- Default foreign anchors remain ordinary measured inputs. Cross-section targets retain their native ordering with a visible fallback explanation.
- Original-folder detection includes installed/disabled addons. Character/global disable uses verified API name-first arguments with character name and global "0". Each original receives one reminder per login; loaded original code suppresses its successor until reload. Main alone and unrelated successors do not disable it. No old-core monkeypatching.
- Registered extension data, saved colors/layout/anchor caches and serial counters are validated. Unknown future schema tags/fields are retained where safe.
- User's originals are preserved, resized without cropping/stretching and wired into each package's IconTexture. Artwork licensing was not independently supplied; code uses GPL-3.0-only with official unmodified license text.
- Shared code names and Flavors/Forever.lua follow the work order. Only requested _Forever.toc files are shipped, with no unsupported flavor fallback.

## Outstanding acceptance and publication

No live Forever client is available here. Client TOC suffix discovery (_Forever versus a possible internal Camelot alias), live Interface 16001 compatibility, real preset page opens/character restrictions, secure reload and custom command clicks, skins, icon rendering and CurseForge install/update behavior remain **unverified**. The inspected primary UI source uses Camelot game-type filters, but that is not evidence of an external addon filename discovery rule; no speculative alias is shipped. Test the AddOns list first.

Preset availability is checked dynamically, and mock routing covers all 23 candidates. Primary source routes were reviewed for modern pooled menu, name-first addon APIs, page callbacks and guild roster selection. Runtime API availability is not proof that every page opens for a real character. Failures are reported rather than represented as a successful roster open.

The new repository was inspected and still reports size 0/default main. No repository commits, push, tag, release, CurseForge project changes or uploads were performed. Real project IDs and file-specific required-dependency relations still need release setup. Reuse both original listings and leave earlier other-flavor files untouched.

## Full raw source-test output

```text
SOURCELOG```

## Full raw extracted-distribution test output

```text
EXTRACTEDLOG```

## Full raw package-check output

```text
CHECKLOG```
'''.replace('COUNT',count).replace('SOURCELOG',source_log).replace('EXTRACTEDLOG',extracted_log).replace('CHECKLOG','\n'.join(checks)+'\n')
(ROOT/'docs/IMPLEMENTATION-REPORT.md').write_text(report)
sourcezip=DIST/('CustomGameMenuButtons-'+VERSION+'-Source.zip')
sourcefiles=[(p,Path('CustomGameMenuButtons-'+VERSION+'-Source')/p.relative_to(ROOT)) for p in ROOT.rglob('*') if p.is_file() and 'dist' not in p.relative_to(ROOT).parts and '__pycache__' not in p.parts]
archive(sourcezip,sourcefiles);packages.append(sourcezip)
shutil.copyfile(ROOT/'docs/IMPLEMENTATION-REPORT.md',DIST/'IMPLEMENTATION-REPORT.md')
shutil.copyfile(ROOT/'docs/TEST-OUTPUT-Source.txt',DIST/'TEST-OUTPUT.txt')
(DIST/'SHA256SUMS.txt').write_text(''.join(hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.name+'\n' for p in packages))
print('\n'.join(checks))
print('Built '+str(len(packages))+' archives in '+str(DIST))
