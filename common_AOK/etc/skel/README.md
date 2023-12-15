
## Prompts

### Coloring

The default prompts are in color and show the following

- username
  - red for root
  - green for other users
- hostname
  - yellow for ssh sessions or when chrooted
  - otherwise same as username color
- cwd (current working directory) - blue

The reason for showing hostname in different colors for remote or chrooted
sessions, is to make it very obvious that this is running on an iSH node.
When on the console you already know, and there is no reason to distract.

### Shell Indicator

The sepparator between hostname and cwd, differs depending on shell, to
make it easier to see what is used.

shell | separator
| - | - |
bash | :
ash | \|
zsh | space

### Battery Charge State

If running on iSH-AOK the prompt will also show battery charge, both by
number and colored to indicate health status of the charge.

level | color | description
| - | - | - |
| <10 | bright red | critically low
| 11-19 | red | very low
| 20-29 | yellow | low
| 30-39 | bright green | lowish
| 40-80 | green | normal
| 81-89 | dark green | highish
| >90 | dark blue | very high
