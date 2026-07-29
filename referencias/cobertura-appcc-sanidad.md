# Cobertura APPCC ALBARABA — Drive, app y EVA

Revisión rápida realizada el 29/07/2026 contra `Manual APPCC.zip`, carpetas reales de Google Drive y la app.

## Resultado

La estructura principal de sanidad está creada en Drive y la app ya conoce las carpetas clave. En esta revisión se han añadido al mapa interno de la app los IDs reales que faltaban para:

- MA01 Diseño del sistema APPCC.
- MA02 Empresa, equipo y compromiso.
- MA03 Listado de productos, recetas, fichas de producto final y fichas de materias primas.
- MA04 Procesos y diagramas.
- MA05 Análisis de peligros y PCC.
- PA01 BPM.
- PA03 Control de plagas.
- PA04 Formación.
- PA08 Trazabilidad como plan de apoyo.

## Matriz de cobertura

| Bloque sanitario | Carpeta Drive | App genera registro/informe | Cola automática Drive/EVA |
|---|---:|---:|---:|
| MA00 Índice y manual | Sí | Manual/índice enlazado | Mapa Drive/EVA |
| MA01 Diseño sistema APPCC | Sí | Documento maestro | Pendiente si se modifica |
| MA02 Empresa/equipo/compromiso | Sí | Configuración empresa | Pendiente si se modifica |
| MA03 Producto, recetas y fichas | Sí | Productos, recetas, fichas proveedor/final | Sí |
| MA04 Procesos, peligros y PCC | Sí | Informe MA04 imprimible | Pendiente si se modifica |
| MA05 Verificación/auditorías | Sí | Auditoría/informes de verificación | Sí |
| F1 MA4 Producción | Sí | Sí | Sí |
| F2 MA05 Recepción materias primas | Sí | Sí | Sí |
| F3 MA4/MA05 Temperatura cámaras | Sí | Sí | Sí |
| F4 MA4 Distribución/servicio | Sí | Sí | Sí |
| F5 MA4 Congelación/descongelación | Sí | Sí | Sí |
| F2 MA4 Control aceite | Sí | Sí | Sí |
| PA01 BPM | Sí | Sí | Sí |
| PA02 Limpieza/desinfección | Sí | Sí | Sí |
| PA03 Plagas | Sí | Sí | Sí |
| PA04 Formación | Sí | Sí | Sí |
| PA05 Proveedores | Sí | Sí | Sí |
| PA06 Mantenimiento/equipos | Sí | Sí | Sí |
| PA07 Agua/contrastación | Sí | Sí | Sí |
| PA08 Trazabilidad | Sí | Sí | Sí |
| PA09 No conformidades | Sí | Sí | Sí |

## Regla de archivo

Si un dato nace en la app, debe quedar en nube y entrar en cola Drive/EVA. EVA debe convertir la cola en archivos finales de Drive cuando corresponda, sin inventar registros ni cerrar APPCC si faltan datos reales.

## Eventos y cliente

Las hojas de servicio, presupuestos y facturas no deben guardarse en carpetas generales duplicadas. Su destino principal es:

`ALBARABA_EMPRESA_GESTION/Eventos/2026/{cliente_evento}`

Dentro de cada expediente de cliente/evento deben ir:

- Hoja de servicio EVA.
- Presupuesto.
- Factura.
- Pedido/cálculo de compras.
- Trazabilidad vinculada al evento.
- APPCC del evento.
- Cobro/cierre.

Las carpetas antiguas de hojas, presupuestos y facturas pueden quedar como histórico o índice, pero no como destino principal nuevo.

## Informes que la cola automática debe preparar

- Libro de movimientos de empresa.
- Recepción de materias primas.
- Stock y lotes de productos/elaboraciones.
- Trazabilidad de lotes.
- Cuentas mensuales.
- Temperaturas de cámaras.
- Limpieza y desinfección.
- BPM.
- Agua.
- Aceites.
- Plagas.
- Formación.
- Mantenimiento.
- No conformidades.
- Abatidor.
- Lavavajillas.
- Residuos.
- Descongelación.
- Regeneración.
- Temperatura de servicio.
- Mapa Drive/EVA.
