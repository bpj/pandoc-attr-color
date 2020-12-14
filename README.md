# attr-color.lua

A [Pandoc][] filter which sets text/background/frame color(s)
on Span and Link elements based on custom Pandoc attributes.

## Version

This document describes version 2020121418 of the filter.

## Usage

    pandoc -L attr-color.lua -o document.ltx document.md

    pandoc -L attr-color.lua -o document.pdf document.md

    pandoc -L attr-color.lua -o document.html document.md

To colorize a Span or Link set one or more of the following custom
attributes on the Span or Link:

| Attribute | Sets color of             |
|-----------|---------------------------|
| `fg`      | **f**ore**g**round (text) |
| `bg`      | **b**ack**g**round        |
| `fr`      | **fr**ame                 |

The value of the attributes should be one of

| Notation    | Description                    |
|-------------|--------------------------------|
| `"#rrggbb"` | RGB color in HTML notation     |
| `"#rgb"`    | Short HTML RGB notation        |
| `ColorName` | [xcolor][]/[CSS][] color name. |

A `ColorName` should be:

-   **If you are producing LaTeX:** a color name from one of the
    predefined [xcolor][] named color sets (described in the section of
    the *xcolor* documentation called *Colors By Name*) loaded by
    Pandoc's `latex` template (unless you want to go through the hassle
    of injecting your own color definitions into the LaTeX preamble!),
    such as `ForestGreen`.

-   **If you are producing HTML**: an HTML or [CSS][] color name.

### Configuration

The filter can be configured by setting certain variables (strings, or
in one case also a boolean) in the document metadata or in the
environment. If both the metadata value and the environment variable are
defined the metadata takes precedence.

| Meta                         | Environment                      | Default               | Description                                                   |
|------------------------------|----------------------------------|-----------------------|---------------------------------------------------------------|
| `attr_color_format`          | `PDC_ATTR_COLOR_FORMAT`          | Current output format | Markup format. A format known to the filter.                  |
| `attr_color_keep_attrs`      | `PDC_ATTR_COLOR_KEEP_ATTRS`      | 'false'               | Whether to keep the `fg`, `bg`, `fr` attributes (false/true). |
| `attr_color_fallback_format` | `PDC_ATTR_COLOR_FALLBACK_FORMAT` | 'html'                | Format to fall back to if (output) format is unknown.         |

### Markup formats vs. Pandoc output formats

The filter "knows", i.e. has code to handle only some Pandoc output
formats, currently

-   `latex`
-   `html`

Usually the filter detects whether the current Pandoc output format is a
known format and falls back to `html` otherwise. Unlike `latex` the
`html` mode does not inject any raw markup into the document, but sets a
CSS `style` attribute on the span or link. This makes it a "safe"
default, since Pandoc will just ignore that attribute for output formats
which don't use CSS styling.

If you for example want to inject the literal raw LaTeX code into your
Markdown document:

``` markdown
[*Foo*]{fg=red}

`\textcolor{red}{`{=latex}*Foo*`\strut}`{=latex}
```

you can call pandoc like this:

``` commandline
pandoc -L attr-color.lua -M attr_color_format=latex document.md -o md-with-latex.md
```

Note that if the format is unknown to the filter (i.e. currently
anything except `latex` or `html`) the filter will fall back on the
fallback format as described under [Configuration][] (by default `html`
and if *that* is also unknown the filter will not do anything.

## RGB notation

In the `#rrggbb` notation each `r`/`g`/`b` stands for an hexadecimal
digit `0-9a-z`, two digits for each of the **r**ed, **g**reen and
**b**lue component of the color. The `#rgb` notation is equivalent to an
`#rrggbb` where both digits in each component are identical, so that for
example `blue`, `#00f` and `#0000ff` are equivalent.

## Unquoted color names

As implied in the table Pandoc generally lets you leave color names,
which contain only ASCII letters and digits, unquoted as attribute
values, but the RGB formats need to be quoted because of the `#`
character.

## Examples

| Markdown                          | LaTeX                                                                 |
|-----------------------------------|-----------------------------------------------------------------------|
| `[Foo]{fg=red}`                   | `\textcolor{red}{Foo\strut}`                                          |
| `[Foo]{fg="#f00"}`                | `\textcolor[HTML]{FF0000}{Foo\strut}`                                 |
| `[Foo]{fg="#ff0000"}`             | `\textcolor[HTML]{FF0000}{Foo\strut}`                                 |
| `[Foo]{fg="#F00"}`                | `\textcolor[HTML]{FF0000}{Foo\strut}`                                 |
| `[Foo]{bg=green}`                 | `\colorbox{green}{Foo\strut}`                                         |
| `[Foo]{bg=yellow fr=blue}`        | `\fcolorbox{blue}{yellow}{Foo\strut}`                                 |
| `[Foo]{fg=red bg=yellow fr=blue}` | `\fcolorbox{blue}{yellow}{\textcolor{red}{Foo\strut}}`                |
| `[Foo]{fg=red fr=blue}`           | `{\color{blue}\fbox{\textcolor{red}{Foo\strut}}}`                     |
| `[Foo]{fr=red}`                   | `{\colorlet{curcolor}{.}\color{red}\fbox{\color{curcolor}Foo\strut}}` |

| Markdown                          | Markdown/CSS                                                                                      |
|-----------------------------------|---------------------------------------------------------------------------------------------------|
| `[Foo]{fg=red}`                   | `[Foo]{style="color: red;"}`                                                                      |
| `[Foo]{fg="#f00"}`                | `[Foo]{style="color: #f00;"}`                                                                     |
| `[Foo]{fg="#ff0000"}`             | `[Foo]{style="color: #ff0000;"}`                                                                  |
| `[Foo]{fg="#F00"}`                | `[Foo]{style="color: #F00;"}`                                                                     |
| `[Foo]{bg=green}`                 | `[Foo]{style="padding: 0.1em; background-color: green;"}`                                         |
| `[Foo]{bg=yellow fr=blue}`        | `[Foo]{style="padding: 0.1em; background-color: yellow; border: 0.01em solid blue;"}`             |
| `[Foo]{fg=red bg=yellow fr=blue}` | `[Foo]{style="padding: 0.1em; color: red; background-color: yellow; border: 0.01em solid blue;"}` |
| `[Foo]{fg=red fr=blue}`           | `[Foo]{style="padding: 0.1em; color: red; border: 0.01em solid blue;"}`                           |
| `[Foo]{fr=red}`                   | `[Foo]{style="padding: 0.1em; border: 0.01em solid red;"}`                                        |

| Markdown                          | Rendered                                                                                                  |
|-----------------------------------|-----------------------------------------------------------------------------------------------------------|
| `[Foo]{fg=red}`                   | <span style="color: red;">Foo</span>                                                                      |
| `[Foo]{fg="#f00"}`                | <span style="color: #f00;">Foo</span>                                                                     |
| `[Foo]{fg="#ff0000"}`             | <span style="color: #ff0000;">Foo</span>                                                                  |
| `[Foo]{fg="#F00"}`                | <span style="color: #F00;">Foo</span>                                                                     |
| `[Foo]{bg=green}`                 | <span style="padding: 0.1em; background-color: green;">Foo</span>                                         |
| `[Foo]{bg=yellow fr=blue}`        | <span style="padding: 0.1em; background-color: yellow; border: 0.01em solid blue;">Foo</span>             |
| `[Foo]{fg=red bg=yellow fr=blue}` | <span style="padding: 0.1em; color: red; background-color: yellow; border: 0.01em solid blue;">Foo</span> |
| `[Foo]{fg=red fr=blue}`           | <span style="padding: 0.1em; color: red; border: 0.01em solid blue;">Foo</span>                           |
| `[Foo]{fr=red}`                   | <span style="padding: 0.1em; border: 0.01em solid red;">Foo</span>                                        |

![Rendered LaTeX example][]

As you can see the LaTeX for frames without background color is a hack.
It could certainly be wrapped in a command, but in that case it would be
necessary to get that command into the LaTeX preamble, which is
non-trivial. Both the filter code and the LaTeX code would be even
prettier if the [adjustbox][] package were used, but again that would
mean getting the `\usepackage{adjustbox}` into the preamble.

## Links

Note that if you use this filter to color links you should *not* use the
[hyperref][] link coloring feature as triggered by `colorlinks` and
other Pandoc variables since the two methods clash.

## Dependencies

-   A version of [pandoc][] which supports Lua filters.
-   The [xcolor][] package. If you produce standalone LaTeX with pandoc,
    such as when producing PDF with Pandoc/LaTeX, the latex template
    loads *xcolor* automatically, along with the `dvipsnames`,
    `svgnames` and `xllnames`. Some older versions of pandoc may not be
    fully supportive, but of course it is a good idea to [update to the
    latest][] anyway.

## Todo

-   Add the necessary metadata trickery to at least optionally use
    [adjustbox][] or at least to inject the code for a `\colorfbox`
    macro so that the LaTeX source doesn't look so ugly.

-   Add an HTML mode which translates the attributes to inline CSS
    `style` attributes.

## Bugs

Report them at <https://github.com/bpj/pandoc-attr-color/issues>

## Author and license

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

The MIT (X11) License

http://www.opensource.org/licenses/mit-license.php

  [Pandoc]: http://pandoc.org/
  [xcolor]: http://texdoc.net/pkg/xcolor
  [CSS]: https://developer.mozilla.org/en-US/docs/Web/CSS/color_value#Color_keywords
  [Configuration]: #configuration
  [Rendered LaTeX example]: https://i.imgur.com/DCD52Ue.png
  [adjustbox]: http://texdoc.net/pkg/adjustbox
  [hyperref]: http://texdoc.net/pkg/hyperref
  [update to the latest]: https://github.com/jgm/pandoc/releases
