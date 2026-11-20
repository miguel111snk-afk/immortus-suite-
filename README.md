# SDK Lua y diagnóstico de OxyBot

`oxy_compat.lua` ofrece detección de funciones, llamadas protegidas, control de frecuencia y limpieza de callbacks. `oxy_probe.lua` toma una instantánea de 13 símbolos del contexto de macros. La sonda solo consulta tipos y entrega los resultados al emisor proporcionado.

Desde un cargador Lua con acceso a `dofile`, carga la sonda y pasa la tabla que el perfil utiliza como entorno de macros. El siguiente ejemplo usa `getfenv(1)` cuando el runtime lo expone.

```lua
local probe = dofile("oxy_probe.lua")
probe.print("OxygenOT Dropbox", getfenv(1), print)
```

Usa el identificador de la compilación activa. La disponibilidad de un símbolo se representa con el tipo observado. El comportamiento de los eventos y la limpieza requieren pruebas en el cliente.

La matriz contiene referencias estáticas del paquete de Dropbox y la evidencia encontrada para las mismas rutas en Drive. El documento de arquitectura amplía el análisis con el build en ejecución, los manifiestos recuperados, el catálogo de bytecode lógico y la tabla de módulos del volcado de diagnóstico. Las pruebas aisladas usan Fengari. La prueba en el cliente sigue pendiente.

Los ZIP `OXY5-originales-por-build.zip` y `OXY5-contenido-verificado.zip` se entregan aparte por su tamaño. El segundo conserva los recursos recuperados para Dropbox, Drive y el build activo. Incluye el manifiesto SHA-256.
