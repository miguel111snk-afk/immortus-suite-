# Arquitectura del cliente OxygenOT y biblioteca para OxyBot

## Build examinada

El paquete de referencia es `/OTCLIENTV8/OxygenOT.zip` de Dropbox. Su SHA-256 es `ccabef08cdef37f8a079d01a611f819755a3e903be595e5fc401997834168ad9`. El análisis abrió también el `data.zip` interno. El inventario remoto de la carpeta expandida tiene 1.685 entradas. El ZIP y su archivo interno aportan 1.506 registros de archivo.

## Capas y puntos de entrada

| Capa | Evidencia y función |
| --- | --- |
| Ejecutables Windows | `OxygenOT_dx.exe` y `OxygenOT_gl.exe`, PE x86. Ambos contienen el literal `LuaJIT 2.1.0-beta3`. El arranque y la versión efectiva del runtime siguen pendientes de prueba. |
| Distribución nativa | `libEGL.dll`, `libGLESv2.dll`, `d3dcompiler_47.dll`, `discord-rpc.dll` y el redistribuible VC x86. Las dependencias por binario y símbolo están en las tablas PE. |
| Recursos | `data.zip!/init.lua` lleva firma OXY5. La carpeta distribuida contiene módulos, mods, layouts, estilos, fuentes, shaders, imágenes y audio. |
| Módulos del cliente | `data/modules` incluye `gamelib`, `game_bot`, `game_cooldown`, `game_inventory`, `game_hotkeys`, `game_battle`, `game_walking` y `game_protocol`. Los OTMOD con firma OXY5 conservan sus rutas, pero sus dependencias internas quedan por recuperar. |
| Perfil OxyBot | `modules/game_bot/default_configs/OxyBot/` contiene `_Loader.lua`, `scripts.lua`, `vBot/`, `cavebot/` y `targetbot/`. Dentro del archivo hay perfiles hermanos `vBot` y `cavebot`. |
| Utilidades del perfil | `vBot/vlib.lua`, `tools.lua`, `items.lua`, `Containers.lua`, `Conditions.lua`, `configs.lua`, `HealBot.lua` y `AttackBot.lua` son puntos de entrada para investigar utilidades y consumidores. |
| Macro | El código del perfil consume registros de eventos, temporizadores y APIs globales del contexto de bot. Para comprobar una API en un perfil concreto, usa su ruta completa, línea y origen registrados en el CSV. |

## Contratos comprobados en el código distribuido

Las líneas de esta tabla corresponden al perfil `OxyBot` de `data.zip`.

| Interfaz | Evidencia | Comportamiento observado |
| --- | --- | --- |
| `canCast(spell, ignoreRL, ignoreCd)` | `vBot/vlib.lua:284` | Devuelve nil si el argumento carece de tipo string. Consulta la tabla local de lanzamientos y después los datos del hechizo. Si faltan ambos puede devolver true. |
| `getSpellData(spell)` | `vBot/vlib.lua:338` | Busca palabras del hechizo en `modules.gamelib.SpellInfo['Default']` y luego en `vBot.customCooldowns`. Devuelve una tabla o false. |
| `getSpellCoolDown(text)` | `vBot/vlib.lua:368` | Devuelve nil sin texto y false sin datos. Consulta iconos de hechizo y grupo en `modules.game_cooldown`. Itera `data.group`. |
| `onTalk` | `vBot/vlib.lua:308` | El consumidor declara un callback con `name, level, mode, text, channelId, pos`. Conserva la última frase del jugador. |
| `onSpellCooldown`, `onGroupSpellCooldown` | `vBot/vlib.lua:314–328` | Comprueba que existan ambos registros. Los callbacks declaran `iconId, duration` y difieren la actualización con `schedule`. |
| `onTextMessage`, `onManaChange` | `cavebot/actions.lua:42`, `vBot/HealBot.lua:709` | Se localizaron consumidores en el perfil. La implementación del registro y su ciclo de vida siguen pendientes de prueba. |

El Atlas Maestro, la base de compatibilidad, la investigación binaria y la matriz de pruebas se consultaron como documentación. Los scripts de Drive provienen de `Mi unidad` y sus carpetas de blueprints. Los ZIP de dumps y las copias sin vínculo confirmado con el build conservan su procedencia. Las coincidencias de `referencias-lua.csv` se extrajeron por patrones y pueden incluir duplicados, cadenas y coincidencias parciales. Los literales HTTP son referencias estáticas. La resolución en ejecución de endpoints, cargas dinámicas y bindings nativos queda abierta.

## Archivos incluidos

| Archivo | Contenido |
| --- | --- |
| `arbol-dropbox.csv` | Árbol recursivo de la carpeta del cliente en Dropbox. |
| `inventario.csv` | Entradas examinadas por origen, tipo, tamaño, firma y SHA-256. |
| `referencias-lua.csv` | 136.955 coincidencias con ruta y línea para definiciones, llamadas, eventos, registros, cargas y URLs. |
| `oxy5.csv` | 1.283 entradas con firma OXY5 y sus primeras 32 bytes, tamaño, hash y entropía. Incluye 189 Lua, 81 OTMOD y 165 OTUI. |
| `binarios-pe.csv`, `símbolos-pe.csv`, `literales-pe.csv` | Extracción estática de siete PE. Incluye arquitectura, secciones, entrada, 5.386 registros de importación y exportación, y literales seleccionados con offset. |
| `oxy_compat.lua` | Biblioteca Lua con detección de APIs, llamadas protegidas, límite de frecuencia por reloj inyectado y conexión reversible de callbacks. Pasó pruebas aisladas en Fengari. |
| `incidencias.csv` | Errores de lectura y análisis registrados durante el recorrido. |

La utilidad se puede cargar desde el mecanismo de módulos del perfil. `Compat.call` devuelve el éxito de la llamada protegida seguido por los resultados de la API. `Compat.throttle` toma un intervalo en milisegundos, un reloj y una acción. `Compat.bind` toma las funciones de conexión y desconexión del entorno, el emisor y la tabla de callbacks. Devuelve una función para dar de baja el registro.

## Comparación con OxygenOT IX_v4 de Drive

Se leyeron todos los archivos del `data.zip` de ambos builds. El build de Dropbox contiene 1.498 recursos y el de Drive contiene 1.506. Hay 1.388 rutas idénticas byte por byte, 110 modificadas y ocho exclusivas de Drive. De esas diferencias, 107 modificaciones y las ocho incorporaciones corresponden a recursos con firma OXY5.

Ambos cargadores importan los estilos UI del perfil seleccionado antes de cargar 34 scripts en orden explícito. La secuencia comienza con `main`, `items`, `vlib`, `new_cavebot_lib` y `configs`. `AttackBot` ocupa la posición 17. La última entrada es `cavebot_control_panel`. Los 34 destinos existen en ambos builds. La prueba de cada cargador en Fengari con dependencias simuladas confirmó la importación de estilos y el orden de carga.

| Archivo | Contenido |
| --- | --- |
| `comparacion-builds.csv` | Todos los recursos internos por ruta, diferencias, tamaño, firma y SHA-256 de cada build. |
| `paquetes-externos.csv` | Directorio de los dos ZIP exteriores, con tamaño y CRC32 por entrada. |
| `orden-carga.csv` | Secuencias completas del cargador de ambos perfiles. |
| `oxy5-comparado.csv` | Manifiesto de 1.283 recursos OXY5 de Dropbox y 1.291 de Drive. |
| `OXY5-originales-por-build.zip` | Archivo independiente con las 2.574 copias binarias completas agrupadas por build, sus rutas originales y el manifiesto SHA-256. |

## Build en ejecución y recuperación OXY5

El cliente observado fue `OxygenOT_gl-1795151631.exe`. Su SHA-256 es `bbf86b562e1510378fab5ee53210fd2dfca37b1b6249e3645494745dd5b09d56`. El `data.zip` activo contiene 1.511 archivos. Frente a Drive se registraron 27 recursos modificados y cinco rutas nuevas.

El ejecutable activo contiene la rutina de lectura de OXY5 en RVA `0x1dd2ff` y el procesamiento criptográfico en RVA `0x493020`. El contenedor tiene una cabecera de 24 bytes, una semilla de 64 bits, longitud comprimida, longitud expandida y Adler-32. El cuerpo contiene un flujo zlib transformado mediante AES-256-GCM con un IV derivado. El archivo observado carece de etiqueta GCM serializada. La recuperación comprobó las longitudes, la integridad zlib y el Adler-32 de cada recurso. El manifiesto registra SHA-256 antes y después de la extracción.

| Build | Archivos en data.zip | OXY5 |
| --- | ---: | ---: |
| Dropbox | 1.498 | 1.283 |
| Drive | 1.506 | 1.291 |
| Activo | 1.511 | 1.296 |
| Total | 4.515 | 3.870 |

Las 3.870 recuperaciones pasaron la verificación de tamaño y SHA-256 después de volver a abrir el ZIP. Hay 1.302 contenedores distintos por SHA-256. Los recursos Lua recuperados incluyen tres `init.lua` en texto y 571 copias de bytecode LuaJIT v2. El bytecode preserva la representación instalada. El texto previo a compilación de esos módulos no está disponible en los paquetes. OTMOD, OTUI, imágenes, sprites y demás recursos conservan sus bytes recuperados y su ruta por build.

## Arranque y callbacks

Los tres `init.lua` cargan `corelib`, alternan cargas automáticas en prioridades 99, 499, 999 y 9999 con `gamelib`, `client` y `game_interface`, y contemplan ramas para `crash_reporter` y `updater`. El build activo también declara la precarga de recursos del cliente después de la carga de prioridad 9999. `game_bot/bot.otmod` declara un módulo en sandbox, carga `bot` y llama a `init()` y `terminate()` en sus respectivos puntos de ciclo de vida.

En el cliente activo, `game_bot/functions/callbacks.lua` contiene los registros de callbacks, y `game_bot/executor.lua` contiene el despacho. El bytecode de `game_bot/bot.lua` conserva nombres de eventos y parámetros. Entre ellos figuran `onTalk(name, level, mode, text, channelId, pos)`, `onTextMessage(mode, text)`, `onManaChange(player, mana, maxMana, oldMana, oldMaxMana)` y los dos eventos de cooldown con `iconId, duration`. Los offsets exactos de identificadores se incluyen en el catálogo para verificar cada ocurrencia.

## Evidencia técnica y límites

| Archivo | Qué permite verificar |
| --- | --- |
| `fuentes-builds.csv`, `inventario-tres-builds.csv` | Paquetes fuente y todas las rutas internas con SHA-256 para los tres builds. |
| `oxy5-recuperado.csv`, `OXY5-contenido-verificado.zip` | Correspondencia entre contenedores y contenido recuperado. El ZIP se entrega aparte. |
| `manifiestos-otmod.csv`, `inicio-modulos.csv` | Scripts, dependencias declaradas, prioridades, puntos de inicio y cierre y orden de arranque. |
| `formatos-recuperados.csv`, `prototipos-luajit.csv`, `identificadores-luajit.csv`, `eventos-bytecode.csv` | Formatos, estructura de 13.580 prototipos, 103.054 constantes de cadena con forma de identificador y offsets de eventos del bot. Una constante por sí sola solo evidencia una referencia. |
| `binarios-tres-builds.csv`, `dependencias-nativas.csv` | 17 archivos PE y 15.452 referencias de importación y exportación. |
| `evidencia-volcados.csv`, `modulos-volcados.csv` | Tres volcados identificados y 99 módulos en el proceso activo. El volcado completo anterior carece de directorio de streams utilizable por el lector. |
| `inventario-externo-y-bot.csv` | Inspección de los ZIP externos y del paquete de bot de la instalación activa. |

El volcado de diagnóstico nuevo se conservó localmente fuera del repositorio. Se verificó la carga de módulos del proceso activo mediante su tabla de módulos. La sonda Lua pasó pruebas aisladas. La ejecución real de la sonda y la prueba de entrega y cancelación de callbacks quedan pendientes porque la ventana activa del juego no expuso una consola accesible. Los archivos del cliente permiten describir dependencias y comportamiento clientes. La implementación interna del servidor queda fuera de esa evidencia.
