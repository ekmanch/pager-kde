# pager-kde

Pager to switch between different virtual desktops for KDE Plasma 6.

Click a desktop to jump to it, or hover the pager and scroll to step through
the desktops. Colours, opacity, size, spacing and margin are configurable.

## Styles

Three styles, selectable in the widget settings.

### Pills

Softly filled dots, with the current desktop drawn as a solid white pill.

![Pills style](docs/media/pill-style.gif)

### Dots

Softly filled dots, with the current desktop drawn as a solid dot.

![Dots style](docs/media/dot-style.gif)

### Numbers

Plain desktop numbers, with the current one coloured.

![Numbers style](docs/media/number-style.gif)

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
