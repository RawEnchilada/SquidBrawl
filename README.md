# Squid Brawl

![Squid Title Card](https://github.com/RawEnchilada/SquidBrawl/raw/main/.docs/TitleCard.png)

Squid Brawl is a direct multiplayer tps game about destroying terrain and knocking your friends into the water using various weapons.

## Technical details

The fully destructible terrain is made up of fixed sized chunks.
It is generated using perlin noise and marching cubes algorithms, which were designed to be usable on their own.

The players are calculated locally and synchronized along all peers, while the projectiles and other objects are processed on the host.
