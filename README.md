# pager-kde

Pager to switch between different virtual desktops for KDE Plasma 6.

Three styles, selectable in the widget settings:

- **Pills**: softly filled dots, with the current desktop drawn as a solid white pill
- **Dots**: softly filled dots, with the current desktop drawn as a solid dot
- **Numbers**: plain desktop numbers, with the current one coloured

Click a desktop to jump to it, or hover the pager and scroll to step through
the desktops. Colours, opacity, size, spacing and margin are configurable.

## Install

```sh
kpackagetool6 -t Plasma/Applet -i package
```

Then add the "Pager" widget to a panel.

## Update

```sh
kpackagetool6 -t Plasma/Applet -u package
systemctl --user restart plasma-plasmashell.service
```

## Try it in a window

```sh
plasmawindowed com.ekmanch.pager
```

## Uninstall

```sh
kpackagetool6 -t Plasma/Applet -r com.ekmanch.pager
```
