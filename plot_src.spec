# -*- mode: python -*-

block_cipher = None


a = Analysis(['plot_src.py'],
             pathex=['/Users/amahmood/Documents/worm_simulation'],
             binaries=None,
             datas=None,
             hiddenimports=[],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=block_cipher)
pyz = PYZ(a.pure, a.zipped_data,
             cipher=block_cipher)
exe = EXE(pyz,
          a.scripts,
          a.binaries,
          a.zipfiles,
          a.datas,
          name='plot_src',
          debug=False,
          strip=False,
          upx=True,
          console=True )
