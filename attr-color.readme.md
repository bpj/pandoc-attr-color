# attr-color.lua

A [Pandoc][] filter which sets LaTeX text/background/frame color(s) on
Span and Div elements based on Pandoc attributes.

## Usage

    pandoc -L attr-color.lua -o document.ltx document.md
    
    pandoc -L attr-color.lua -o document.pdf document.md

To colorize a Span or Link set one or more of the following custom  attributes
on the Span or Link:

| Attribute | Sets color of
|-----------|-----------------------------
| `fg`      | **f**ore**g**round (text)
| `bg`      | **b**ack**g**round
| `fr`      | **fr**ame

The value of the attributes should be one of

| Notation    | Description
|-------------|---------------------------
| `"#rrggbb"` | RGB color in HTML notation
| `"#rgb"`    | Short HTML RGB notation
| `ColorName` | [xcolor][] color name.

A `ColorName` should be a color name from one of the predefined [xcolor][]
named color sets (described in an appendix of the *xcolor*
documentation) loaded by Pandoc's `latex` template (unless you want to go
through the hassle of injecting your own color definitions into the LaTeX
preamble!), such as `ForestGreen`.

In the `#rrggbb` notation each `r`/`g`/`b` stands for an hexadecimal digit
`0-9a-z`, two digits for each of the **r**ed, **g**reen and **b**lue component
of the color.  The `#rgb` notation is equivalent to an `#rrggbb` where both
digits in each component are identical, so that for example `blue`, `#00f` and
`#0000ff` are equivalent.

As implied in the table Pandoc generally lets you leave color names, which
contain only ASCII letters and digits, unquoted as attribute values, but the
RGB formats need to be quoted because of the `#` character.

## Examples

| Markdown                         | LaTeX
|----------------------------------|--------------------------------------------------------------------
| [Foo]{fg=red}                    | `\textcolor{red}{Foo\strut}`
| [Foo]{fg="#f00"}                 | `\textcolor[HTML]{FF0000}{Foo\strut}`
| [Foo]{fg="#ff0000"}              | `\textcolor[HTML]{FF0000}{Foo\strut}`
| [Foo]{fg="#F00"}                 | `\textcolor[HTML]{FF0000}{Foo\strut}`
| [Foo]{bg=green}                  | `\colorbox{green}{Foo\strut}`
| [Foo]{bg=yellow fr=blue}         | `\fcolorbox{blue}{yellow}{Foo\strut}`
| [Foo]{fg=red bg=yellow fr=blue}  | `\fcolorbox{blue}{yellow}{\textcolor{red}{Foo\strut}}`
| [Foo]{fg=red fr=blue}            | `{\color{blue}\fbox{\textcolor{red}{Foo\strut}}}`
| [Foo]{fr=red}                    | `{\colorlet{curcolor}{.}\color{red}\fbox{\color{curcolor}Foo\strut}}`

![Rendered example](attr-color.png)

As you can see the LaTeX for frames without background color is a hack. It
could certainly be wrapped in a command, but in that case it would be necessary
to get that command into the LaTeX preamble, which is non-trivial. Both
the filter code and the LaTeX code would be even prettier if the [adjustbox][]
package were used, but again that would mean getting the
`\usepackage{adjustbox}` into the preamble.

## Links

Note that if you use this filter to color links you should *not* use the
[hyperref][] link coloring feature as triggered by `colorlinks` and other
Pandoc variables since the two methods clash.

## Dependencies

-   A version of [pandoc][] which supports Lua filters.
-   The [xcolor][] package.  If you produce standalone LaTeX with pandoc,
    such as when producing PDF with Pandoc/LaTeX, the latex template loads
    *xcolor* automatically, along with the `dvipsnames`, `svgnames` and
    `xllnames`. Some older versions of pandoc may not be fully supportive,
    but of course it is a good idea to [update to the latest][] anyway.

## Todo

-   Add the necessary metadata trickery to at least optionally use
    [adjustbox][] or at least to inject the code for a `\colorfbox` macro so
    that the LaTeX source doesn't look so ugly.

-   Add an HTML mode which translates the attributes to inline CSS `style`
    attributes.

## Bugs

Report them at

## Author and license

This software is Copyright (c) 2020 by Benct Philip Jonsson.

This is free software, licensed under:

  The MIT (X11) License

http://www.opensource.org/licenses/mit-license.php


[pandoc]: http://pandoc.org/
[xcolor]: http://texdoc.net/pkg/xcolor
[adjustbox]: http://texdoc.net/pkg/adjustbox
[hyperref]: http://texdoc.net/pkg/hyperref
[update to the latest]: https://github.com/jgm/pandoc/releases
