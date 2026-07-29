# Cobertura APPCC ALBARABA — Drive, app y EVA

Revisión realizada el 29/07/2026 contra:

- `C:\Users\lidia\Downloads\Manual APPCC.zip`
- Carpetas reales de Google Drive `ALBARABA_APPCC_SANIDAD`
- Código actual de la app `index.html`
- Acciones disponibles del conector `ALBARABA APPCC Seguro`

## Resumen ejecutivo

La estructura de carpetas de sanidad está creada en Drive y la app conoce los IDs reales de las carpetas principales y subcarpetas importantes.

La app tiene implantados los registros operativos principales: recepción, temperaturas, limpieza, producción/elaboraciones, trazabilidad, congelación/descongelación, regeneración, abatidor, lavavajillas, residuos, BPM, agua, aceite, plagas, formación, mantenimiento y no conformidades.

El punto que queda por validar con una prueba real no es la existencia de carpetas ni de pantallas, sino el ciclo completo:

1. Registrar datos reales en la app.
2. Preparar/encolar informe.
3. Que EVA/Drive genere el archivo final.
4. Que el PDF/documento aparezca en la carpeta correcta.
5. Que no se marque APPCC como completo si faltan registros reales.

## Carpetas comprobadas en Drive

### Carpeta raíz

`ALBARABA_APPCC_SANIDAD`

Contiene:

- `00_Indice_y_Manual`
- `01_Diseno_Sistema_APPCC`
- `02_Empresa_Equipo_Compromiso`
- `03_Producto_Recetas_Fichas`
- `04_Procesos_Diagramas_Flujo`
- `05_Analisis_Peligros_PCC`
- `06_Registros_APPCC`
- `07_Verificacion_Auditorias`
- `08_Planes_Apoyo`
- `09_Cierres_Mensuales`
- `99_Obsoletos`

### Producto, recetas y fichas

`03_Producto_Recetas_Fichas` contiene:

- `Listado_productos`
- `Recetas`
- `Fichas_producto_final`
- `Fichas_materias_primas_proveedores`

### Registros APPCC

`06_Registros_APPCC` contiene:

- `F1_Registro_Produccion`
- `F2_Recepcion_Materias_Primas`
- `F3_Temperatura_Camaras`
- `F4_Distribucion`
- `F5_Congelacion_Descongelacion`
- `Control_Aceite`
- `Trazabilidad_Lotes`

### Planes de apoyo

`08_Planes_Apoyo` contiene:

- `PA01_BPM_Buenas_Practicas`
- `PA02_Limpieza_Desinfeccion`
- `PA03_Control_Plagas`
- `PA04_Formacion`
- `PA05_Proveedores`
- `PA06_Mantenimiento_Equipos`
- `PA07_Control_Agua`
- `PA08_Trazabilidad`
- `PA09_No_Conformidades_Acciones_Correctivas`

## Matriz de implantación

| Bloque del manual / sanidad | Carpeta Drive creada | App tiene datos/pantalla | App genera informe imprimible | Cola Drive/EVA preparada | Estado |
|---|---:|---:|---:|---:|---|
| MA00 Índice y manual | Sí | Parcial | Parcial | Sí, mapa Drive/EVA | Parcial: falta subir/actualizar documentos maestros finales |
| MA01 Diseño del sistema APPCC | Sí | Parcial | MA04/APPCC parcial | Parcial | Parcial: documento maestro debe quedar en Drive |
| MA01.1 Equipo APPCC | Sí | Parcial, configuración empresa/usuarios | Parcial | Parcial | Parcial: falta documento maestro final |
| MA01.2 Compromiso seguridad | Sí | No como formulario específico | No | No específico | Falta documento fijo o plantilla |
| MA01.3 Legislación aplicable | Sí | No como formulario específico | No | No específico | Falta documento fijo o plantilla |
| MA01.4 Plano | Sí | No | No | No específico | Falta adjuntar plano real |
| MA02 Descripción producto | Sí | Sí, productos/recetas/fichas | Sí | Sí | Cubierto operativo |
| MA02.1 Listado productos | Sí | Sí, productos | Sí | Sí | Cubierto |
| MA02.2 Recetas | Sí | Sí, recetas/elaboraciones | Sí | Sí | Cubierto |
| Fichas producto final | Sí | Sí, fichas de elaboración | Sí | Sí | Cubierto, hay que ir completando recetas reales |
| Fichas materias primas proveedor | Sí | Sí, subida ficha proveedor | Parcial | Sí | Cubierto parcial: comprobar archivo final en Drive |
| MA03 Descripción proceso | Sí | Parcial | MA04/procesos parcial | Parcial | Parcial: falta documento/diagrama maestro completo |
| MA03 Diagramas de flujo | Sí | Parcial | MA04 imprimible | Parcial | Parcial: falta guardar diagramas finales |
| MA04 Análisis peligros y PCC | Sí | Sí, tabla MA04 | Sí | Parcial | Cubierto funcional, falta validar archivo Drive |
| F1 MA4 Producción | Sí | Sí, elaboraciones/producción | Sí | Sí | Cubierto |
| F2 MA4 Control aceite | Sí | Sí | Sí | Sí | Cubierto |
| F3 MA4 Temperaturas cámaras | Sí | Sí | Sí | Sí | Cubierto |
| F4 MA4 Distribución | Sí | Sí, temperatura servicio/distribución | Sí | Sí | Cubierto |
| F5 MA4 Congelación/descongelación | Sí | Sí | Sí | Sí | Cubierto |
| MA05 Verificación sistema | Sí | Parcial, verificación/informes | Sí parcial | Sí | Parcial: falta rutina mensual probada |
| F1 MA5 Auditoría interna | Sí | Parcial | Parcial | Sí | Parcial: falta formulario/auditoría guiada completa |
| PA01 BPM | Sí | Sí | Sí | Sí | Cubierto |
| PA02 Limpieza/desinfección | Sí | Sí | Sí | Sí | Cubierto |
| PA03 Plagas | Sí | Sí | Sí | Sí | Cubierto |
| PA04 Formación | Sí | Sí | Sí | Sí | Cubierto |
| PA05 Proveedores | Sí | Sí | Sí | Sí | Cubierto |
| PA06 Mantenimiento equipos | Sí | Sí | Sí | Sí | Cubierto |
| PA07 Control agua/contrastación | Sí | Sí | Sí | Sí | Cubierto |
| PA08 Trazabilidad | Sí | Sí | Sí | Sí | Cubierto |
| PA09 No conformidades | Sí | Sí | Sí | Sí | Cubierto |
| Abatidor | Carpeta sanitaria conectada a Producción | Sí | Sí | Sí | Cubierto |
| Lavavajillas | Carpeta sanitaria conectada a Verificación | Sí | Sí | Sí | Cubierto |
| Residuos | Carpeta sanitaria conectada a Verificación/BPM | Sí | Sí | Sí | Cubierto |
| Regeneración | Carpeta sanitaria conectada a Producción | Sí | Sí | Sí | Cubierto |
| Temperatura servicio | Carpeta sanitaria conectada a Distribución | Sí | Sí | Sí | Cubierto |

## Qué puede rellenar la app ahora

La app puede registrar y preparar informes de:

- Recepción de materias primas: proveedor, producto, temperatura, lote, caducidad, conformidad y empleado.
- Temperaturas de cámaras.
- Limpieza y desinfección.
- Producción/elaboraciones.
- Stock y lotes.
- Trazabilidad.
- Congelación y descongelación.
- Regeneración.
- Abatidor.
- Lavavajillas.
- Residuos orgánicos.
- Temperatura de servicio.
- BPM.
- Aceite.
- Agua y contrastación.
- Plagas.
- Formación.
- Mantenimiento.
- No conformidades y acciones correctivas.
- Productos sin ficha técnica por proveedor.
- Fichas de elaboración, alérgenos y fichas técnicas de proveedor.

## Qué puede hacer EVA ahora

El conector `ALBARABA APPCC Seguro` permite:

- Crear eventos en Planificación EVA.
- Actualizar eventos existentes.
- Consultar estado operativo/comercial/documental de un evento.
- Consultar registros APPCC reales asociados a un evento.
- Consultar catálogo real de elaboraciones.
- Enviar documentos de proveedor/albaranes/facturas para revisión humana.

EVA debe usar esos datos para preparar el expediente, pero no debe declarar completado APPCC si la app no devuelve registros reales.

## Puntos pendientes o débiles

Estos puntos no están demostrados al 100% hasta hacer prueba real:

1. Que la cola Drive/EVA termine creando el PDF/documento final en la carpeta correcta sin intervención manual.
2. Que los documentos maestros del manual estén subidos como versión vigente en Drive:
   - diseño del sistema,
   - equipo APPCC,
   - compromiso,
   - legislación,
   - plano,
   - descripción de procesos,
   - diagramas de flujo,
   - validación/verificación.
3. Que cada ficha técnica de proveedor subida en la app tenga también copia/enlace final en Drive.
4. Que el cierre mensual APPCC genere un paquete completo y quede guardado en `09_Cierres_Mensuales`.
5. Que EVA pueda leer la cola Drive/EVA y colocar cada archivo final sin confundir carpetas de evento con carpetas sanitarias.

## Regla de archivo

### Carpeta de evento/cliente

Van dentro del expediente del cliente/evento:

- Hoja de servicio EVA.
- Presupuesto.
- Factura.
- Pedido/cálculo de compras del evento.
- Documentación final del evento.
- Trazabilidad vinculada al evento.

Destino:

`ALBARABA_EMPRESA_GESTION/Eventos/2026/{cliente_evento}`

### Carpeta APPCC Sanidad

Van dentro del archivador sanitario:

- Registros generales APPCC.
- Informes diarios/mensuales.
- Trazabilidad sanitaria.
- Fichas técnicas.
- Planes de apoyo.
- Verificaciones y auditorías.
- Cierres mensuales.

Destino:

`ALBARABA_APPCC_SANIDAD`

## Prueba real recomendada

Para confirmar que todo funciona de punta a punta:

1. Crear evento de prueba con EVA.
2. Enviarlo a Planificación EVA.
3. Registrar una recepción de materia prima con lote.
4. Registrar temperatura de cámara.
5. Crear una elaboración vinculada al evento.
6. Registrar abatidor o regeneración si aplica.
7. Generar trazabilidad.
8. Crear una no conformidad pequeña de prueba y cerrarla.
9. Pulsar `Cola Drive / EVA > Preparar ahora`.
10. Pedir a EVA que archive los paquetes pendientes en Drive.
11. Comprobar que aparecen los archivos en:
    - carpeta del evento,
    - carpeta sanitaria correspondiente,
    - cierre mensual si aplica.

## Veredicto

La base está bien montada. Para uso interno y preparación de inspección está muy avanzada.

No obstante, antes de decir “sanidad lo tiene todo perfecto”, falta hacer una prueba real de generación y archivo automático en Drive, especialmente documentos finales PDF y documentos maestros vigentes.
