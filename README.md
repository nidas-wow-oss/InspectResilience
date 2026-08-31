# Inspect Stats Panel

Addon para **World of Warcraft 3.3.5a (WotLK)** que agrega un panel de estadísticas a la ventana de inspeccionar: cuando mirás el equipo de otro jugador, te muestra su **resiliencia** y el resto de sus stats de combate calculados a partir del equipo que lleva puesto.

**Versión:** 2.5 · **Autor:** Nidhaus

## Para qué sirve

En PvP saber la resiliencia del rival antes de pelear cambia la decisión de abrir o no. WoW 3.3.5a no muestra ese dato al inspeccionar, así que el addon lo calcula sumando el equipo del objetivo y lo presenta en un panel al costado de la ventana de inspección.

## Qué hace

- Muestra la **resiliencia** total del jugador inspeccionado.
- Muestra el resto de **estadísticas de combate** derivadas del equipo.
- Se integra en la ventana de inspección estándar, sin abrir ventanas aparte.
- Activo por defecto (`## DefaultState: enabled`), no requiere configuración.

## Instalación

1. Cerrá el juego.
2. Copiá la carpeta `InspectResilience` dentro de `World of Warcraft\Interface\AddOns\`.
3. Iniciá el juego y activá el addon en el selector de la pantalla de personajes.

## Comandos

| Comando | Qué hace |
|---|---|
| `/ires` | Abre las opciones del addon |
| `/isp` | Alias corto |
| `/inspectstats` | Alias largo |

## Compatibilidad

Interface 30300 — WotLK 3.3.5a. Probado en Warmane.

## Licencia

Uso libre. Si lo redistribuís o lo usás como base, mantené el crédito al autor.
