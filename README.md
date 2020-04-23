Updated script for better plist watchlists, improved functionality of script.

The credit for most of the original code belongs to others including:
- https://github.com/CoolCyberBrain/toggleairport.git
- https://github.com/paulbhart/toggleairport
- https://gist.github.com/albertbori/1798d88a93175b9da00b

This program turns off wireless when it detects a wired ethernet connection and turns on wireless when the ethernet is unplugged. It will also respect your choice if you manually turn wireless back on.

## For Catalina and later ##
Tested on Catalina

```bash
git clone https://github.com/mikeabreu/toggleairport
cd toggleairport
./install.sh
```

to uninstall just do
```bash
./uninstall.sh
```

Note: Do not run either of the scripts with sudo, if you do, notifications will not display.
Note: You can remove the toggleairport directory after installing, it's not needed. If you want to uninstall later just clone and run uninstaller, or just manually uninstall.

TODO:
- Add logic to check if ethernet connection has Internet before dropping off wireless.