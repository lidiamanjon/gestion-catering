# Manual APPCC ALBARABA — estructura documental para Drive, app y EVA

Revisión inicial realizada desde `Manual APPCC.zip` recibido el 29/07/2026.

## 1. Documentos del manual detectados

### Manual APPCC

- `MA 00` — Índice de documentos y registros.
- `MA 01` — Diseño del sistema APPCC.
- `MA 01-1` — Legislación aplicable y documentación de referencia.
- `MA 02` — Descripción de la empresa y del equipo APPCC.
- `MA 02-1` — Compromiso con la seguridad del producto.
- `MA 03` / `MA 2` — Descripción del producto.
- `MA 03-1` — Fichas técnicas de producto final.
- `MA 04` / `MA 3` — Descripción del proceso y diagramas de flujo.
- `MA 05` / `MA 4` — Cuadros de gestión, análisis de peligros y PCC.
- `MA 06` / `MA 5` — Verificación, validación y auditoría del sistema.

### Registros operativos APPCC detectados

- `F1 MA4` / `F1 MA05` — Registro de producción.
- `F2 MA05` — Registro de recepción de materias primas.
- `F3 MA4` / `F3 MA05` — Registro de temperatura de cámaras.
- `F4 MA4` / `F4 MA05` — Registro de distribución.
- `F5 MA4` — Registro de congelación / descongelación.
- `F2 MA4` — Control de aceite.
- `F1 MA5` / `F1 MA06` — Auditoría interna / auditoría de seguimiento APPCC.

### Planes de apoyo detectados en índice

- `PA 01` — Plan de Buenas Prácticas de Manipulación.
- `F1 PA 01` — Auditoría de cumplimiento BPM.
- `F2 PA 01` — Especificaciones de materias primas.
- `PA 02` — Plan de limpieza y desinfección.
- `F1 PA 02` — Registro de limpieza y desinfección.
- `F2 PA 02` — Listado de productos de limpieza y desinfección.
- `PA 03` — Plan de control de plagas.
- `PA 04` — Plan de formación.
- `F1 PA 04` — Registro de formación.
- `PA 05` — Plan de control de proveedores.
- `PA 05-01` — Listado de proveedores.
- `F1 PA 05` — Ficha de proveedor.
- `PA 06` — Plan de mantenimiento de maquinaria e instalaciones.
- `PA 06-01` — Listado de equipos.
- `F1 PA 06` — Ficha de mantenimiento de equipos.
- `F2 PA 06` — Ficha de contrastación de equipos.
- `F3 PA 06` — Ficha de instalaciones.
- `F4 PA 06` — Etiquetas de contrastación.
- `F5 PA 06` — Registro de averías.
- `PA 07` — Plan de control de agua.
- `PA 08` — Plan de trazabilidad de los productos.
- `PA 09` — Plan de No Conformidades y Acciones Correctivas.
- `F1 PA 09` — Informe de No Conformidad.
- `F2 PA 09` — Informe de Acción Correctiva.

## 2. Estructura recomendada en Drive

```text
ALBARABA_APPCC_SANIDAD
├── 00_Indice_y_Manual
├── 01_Diseno_Sistema_APPCC
├── 02_Empresa_Equipo_Compromiso
├── 03_Producto_Recetas_Fichas
│   ├── Listado_productos
│   ├── Recetas
│   ├── Fichas_producto_final
│   └── Fichas_materias_primas_proveedores
├── 04_Procesos_Diagramas_Flujo
├── 05_Analisis_Peligros_PCC
├── 06_Registros_APPCC
│   ├── F1_Registro_Produccion
│   ├── F2_Recepcion_Materias_Primas
│   ├── F3_Temperatura_Camaras
│   ├── F4_Distribucion
│   ├── F5_Congelacion_Descongelacion
│   ├── Control_Aceite
│   └── Trazabilidad_Lotes
├── 07_Verificacion_Auditorias
├── 08_Planes_Apoyo
│   ├── PA01_BPM
│   ├── PA02_Limpieza_Desinfeccion
│   ├── PA03_Control_Plagas
│   ├── PA04_Formacion
│   ├── PA05_Proveedores
│   ├── PA06_Mantenimiento_Equipos
│   ├── PA07_Control_Agua
│   ├── PA08_Trazabilidad
│   └── PA09_No_Conformidades
├── 09_Cierres_Mensuales
└── 99_Obsoletos
```

## 3. Nombres normalizados de archivos

Usar siempre fecha ISO `AAAA-MM-DD` o mes `AAAA-MM`.

```text
MA00_Indice_Documentos_Registros_revXX.pdf
MA01_Diseno_Sistema_APPCC_revXX.pdf
MA02_Empresa_Equipo_APPCC_revXX.pdf
MA03_Descripcion_Producto_revXX.pdf
MA04_Descripcion_Proceso_Diagramas_revXX.pdf
MA05_Analisis_Peligros_PCC_revXX.pdf
MA06_Verificacion_Sistema_revXX.pdf

AAAA-MM_F3MA4_Temperatura_Camaras.pdf
AAAA-MM-DD_F1MA4_Registro_Produccion.pdf
AAAA-MM-DD_F2MA05_Recepcion_Materias_Primas.pdf
AAAA-MM-DD_F4MA4_Distribucion_Cliente_Evento.pdf
AAAA-MM-DD_F5MA4_Congelacion_Descongelacion.pdf
AAAA-MM-DD_F2MA4_Control_Aceite.pdf
AAAA-MM_F1MA5_Auditoria_Interna.pdf
AAAA-MM-DD_PA09_No_Conformidad_Accion_Correctiva.pdf
AAAA-MM-DD_Trazabilidad_Lotes_Cliente_Evento.pdf
```

## 4. Correspondencia con la app

| Manual | Debe generarlo/controlarlo la app | Observaciones |
|---|---|---|
| F1 MA4 Registro de producción | Sí | Elaboración, lote, cantidad, envasado, tratamiento térmico, abatimiento/enfriamiento, regeneración, responsable. |
| F2 MA05 Recepción materias primas | Sí | Producto, proveedor, lote, caducidad, transporte, envase, etiqueta, temperatura, observaciones, firma/responsable. |
| F3 MA4 Temperatura cámaras | Sí | Inicio y fin de jornada por cámara: materias primas, producto final y congelación. |
| F4 MA4 Distribución | Sí | Fecha, producto, lote, temperatura, cantidad, cliente, tipo transporte/refrigerado/caliente, firma. |
| F5 MA4 Congelación/descongelación | Sí | Producto, cantidad, fecha congelación, fecha descongelación, responsable. |
| F2 MA4 Control aceite | Sí | Fecha, compuestos polares, aspecto, apto/no apto, cambio de aceite, responsable. |
| F1 MA5 Auditoría interna | Parcial | Checklist anual; mejor conservar plantilla oficial y que la app genere evidencias. |
| PA02 Limpieza/desinfección | Sí | Registros diarios/semanales/mensuales según plan. |
| PA04 Formación | Sí | Empleado, formación, fecha, firma/evidencia. |
| PA05 Proveedores | Sí | Listado, ficha, documentación/fichas técnicas pendientes. |
| PA06 Mantenimiento/equipos | Sí | Mantenimiento, averías, contrastación/calibración. |
| PA07 Agua | Sí | Registros/control cuando aplique. |
| PA09 No conformidades | Sí | Incidencia, acción correctiva, responsable, cierre y evidencias. |

## 5. Reglas para EVA

- EVA puede archivar informes y mover documentos a Drive.
- EVA no debe dar por completo un registro APPCC si no existe registro real en la app.
- Si faltan lote, temperatura, fecha, proveedor, cliente o responsable, EVA debe marcarlo como `pendiente_revision_humana`.
- Las carpetas de eventos deben recibir copias de los documentos APPCC que afecten al evento, pero el original sanitario mensual debe quedar en `ALBARABA_APPCC_SANIDAD`.
- Los documentos obsoletos del ZIP deben ir a `99_Obsoletos`, no mezclados con documentos vigentes.

