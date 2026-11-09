# Historias de usuario · PrestaLab

Alcance: historias Must (ciclo del préstamo, catálogo, disponibilidad, solicitud y acceso) y Should (control, seguridad de cuentas y reportes) del dominio de PrestaLab, partiendo de las secciones 1.1 y 1.2 de `readme.md` y de las decisiones del usuario. Dominio y regla de disponibilidad según `CLAUDE.md`. El prefijo HU identifica las historias Must y el prefijo SH las Should.

Estado de las decisiones: están confirmadas por el usuario PA-1 a PA-36 (incluidos el límite de 3 préstamos en curso, la cancelación por el estudiante sin aprobaciones parciales, el cierre automático de no recogidos, el horario de servicio de 8:00 AM a 5:00 PM con plazo de recogida de 2 horas de servicio y el rango efectivo de retención de unidades). La sesión única por usuario es una decisión del usuario recogida en `CLAUDE.md`. Regla general de inicio de sesión: ningún mensaje de acceso o de bloqueo revela si un correo existe ni qué dato es correcto. La baja de una cuenta no se permite con préstamos en curso de ningún tipo (PA-29) y el registro puede indicar que un correo ya tiene cuenta (PA-34, limitación aceptada). También están confirmados los textos de sesión no válida y sesión desplazada (PA-33) y la ventana del límite por origen de conexión (PA-35). El mensaje de rechazo de la baja, "La cuenta tiene préstamos en curso", también está confirmado (PA-36). No queda ninguna decisión pendiente ni pregunta abierta.

## Convenciones comunes

- **Rango de fechas:** se expresa con fecha de inicio y fecha de fin, ambas incluidas. Duración en días = fin - inicio + 1. Ejemplo: del 10 al 16 son 7 días (válido); del 10 al 17 son 8 días (rechazado). La fecha de fin no puede ser anterior a la de inicio. La regla "inicio no anterior a hoy" aplica solo a la consulta de disponibilidad (HU-03) y a la solicitud (HU-04); los filtros de SH-01, SH-04 y SH-05 aceptan fechas pasadas.
- **Rangos que se cruzan:** dos rangos se cruzan si comparten al menos un día. Un préstamo que termina el 12 y otro que empieza el 12 se cruzan.
- **Préstamo activo:** el que está en estado APROBADO, ENTREGADO o VENCIDO.
- **ENTREGADO dentro de plazo:** préstamo ENTREGADO cuya fecha fin efectiva es hoy o posterior. Con fecha fin efectiva anterior a hoy está atrasado (VENCIDO si SH-02 ya lo marcó).
- **Equipo activo:** equipo no dado de baja (en DISPONIBLE o MANTENIMIENTO).
- **Titular del préstamo:** el ESTUDIANTE que hizo la solicitud; es quien recibe las alertas del préstamo y quien responde por él.
- **Horario de servicio:** de 8:00 AM a 5:00 PM, hora local de la institución. Las aprobaciones y las entregas solo se hacen dentro de ese horario (ambas horas incluidas).
- **Plazo de recogida:** 2 horas de servicio contadas desde la hora de aprobación; si se aprobó antes del día de inicio, cuentan desde las 8:00 AM del día de inicio (plazo hasta las 10:00 AM). Las aprobaciones solo ocurren de 8:00 AM a 5:00 PM. Si las 2 horas no caben en el día, el resto se cuenta desde las 8:00 AM del día siguiente (aprobación a las 4:00 PM: plazo hasta las 9:00 AM del día siguiente; a las 5:00 PM: hasta las 10:00 AM del día siguiente). **Excepción para préstamos de 1 día** (fecha fin igual a fecha de inicio): si se aprueban después de las 3:00 PM, el plazo llega hasta las 10:00 AM del día siguiente (3:00 PM exactas: plazo hasta las 5:00 PM; 3:01 PM: 10:00 AM del día siguiente). La excepción y la regla general se mantienen tal como están escritas (confirmado, PA-26). El plazo puede sobrepasar la fecha fin del préstamo; el préstamo APROBADO retiene sus unidades según el rango efectivo de retención (ver "Unidades retenidas") y el cierre automático no ocurre antes del fin del plazo. Al vencer el plazo sin entrega, el préstamo se cierra como no recogido (HU-05e). Las horas solo importan para aprobar, entregar y este plazo; el resto de las reglas trabaja con fechas.
- **Fecha fin efectiva:** es la fecha fin del préstamo, salvo que se entregue después de ella (plazo cruzado al día siguiente); en ese caso es el día de la entrega. Debe devolverse ese mismo día; si no, el sistema lo marca VENCIDO en la siguiente revisión de las 00:05 y el retraso (SH-03) se calcula desde la fecha fin efectiva. La fecha fin efectiva no cambia la retención de unidades (esta dura hasta la devolución, PA-28). (confirmado, PA-25).
- **Préstamo en curso:** el que está en estado SOLICITADO, APROBADO, ENTREGADO o VENCIDO. Cuenta para el límite de 3 de HU-04 (PA-10 y PA-23 confirmadas). Un préstamo RECHAZADO, CANCELADO o DEVUELTO no cuenta.
- **Unidades retenidas y rango efectivo de retención:** cada préstamo retiene sus unidades en su rango efectivo de retención. Para un APROBADO, va desde su fecha de inicio hasta el día en que vence su plazo de recogida o su fecha fin, el que sea posterior (por ejemplo, un préstamo de 1 día del 10 aprobado a las 5:00 PM retiene el 10 y el 11). Para un ENTREGADO o VENCIDO, retiene desde su inicio hasta el día de su devolución; para la disponibilidad solo importan los días desde hoy (mientras no se devuelva, cubre su rango y, si su fecha fin ya pasó, cada día desde hoy hasta la devolución). La fecha fin efectiva no limita la retención; solo sirve para decidir cuándo vence el préstamo (SH-02) y cuántos días de retraso tiene (SH-03). Una solicitud que se evalúa para aprobar se trata como si ya estuviera aprobada ahora: su rango efectivo es el que tendría al aprobarse (desde su inicio hasta el día en que vencería su plazo de recogida o su fecha fin, el que sea posterior). Se usa en la disponibilidad de HU-03, en la verificación de HU-05a y en las unidades-día de SH-04. Confirmado por el usuario (PA-28); la fórmula de disponibilidad de `CLAUDE.md` ya está alineada. Los estados SOLICITADO, RECHAZADO, CANCELADO y DEVUELTO no retienen unidades. Así la retención no depende de que exista el estado VENCIDO (SH-02).
- **Extensiones del dominio (confirmadas):** un préstamo ENTREGADO o VENCIDO con fecha fin pasada sigue reteniendo unidades hasta devolverse (PA-13); la transición VENCIDO -> DEVUELTO es válida (PA-14); un APROBADO no recogido pasa a RECHAZADO con motivo "No recogido" (PA-12, cierre automático); el estudiante titular puede cancelar su solicitud en cualquier momento antes de la entrega (PA-11 y PA-24, confirmados), lo que introduce el estado CANCELADO como extensión del dominio; una SOLICITADO no resuelta al pasar su fecha de inicio se rechaza sola con el motivo "Sin resolver a tiempo" (RN-05a.11, confirmado, PA-27).
- **Mensajes de error** alineados con el readme (sección 5): "Unidades insuficientes", "Acceso denegado", y la etiqueta "No disponible" para equipos en mantenimiento.

## Índice

| ID | Título | Rol | Prioridad | Justificación |
|---|---|---|---|---|
| HU-01a | Registro de cuenta de estudiante | ESTUDIANTE | Must | Sin identidad no hay responsable del préstamo. |
| HU-01b | Inicio de sesión y acceso según rol | Todos los roles | Must | Sin sesión y permisos por rol no se puede operar ni proteger el inventario. |
| HU-02a | Crear y editar equipos del catálogo | ENCARGADO | Must | Sin equipos registrados no hay nada que prestar. |
| HU-02b | Dar de baja un equipo | ENCARGADO | Must | Evita ofrecer equipos retirados conservando el historial (baja lógica exigida por el readme). |
| HU-03 | Consulta de disponibilidad | ESTUDIANTE | Must | Evita desplazamientos inútiles y es la base de la solicitud. |
| HU-04 | Solicitud de préstamo | ESTUDIANTE | Must | Es el núcleo del propósito: pedir equipos y ver el estado de lo pedido. Ver PA-10. |
| HU-05a | Aprobar o rechazar solicitudes | ENCARGADO | Must | Sin decisión no avanza ningún préstamo. Ver PA-11. |
| HU-05b | Registrar la entrega | ENCARGADO | Must | Deja constancia de quién tiene cada equipo y desde cuándo. |
| HU-05c | Registrar la devolución | ENCARGADO | Must | Cierra el ciclo y libera las unidades. |
| HU-05d | Registrar la devolución con daños o pérdidas | ENCARGADO | Must | Evita ofrecer unidades dañadas o perdidas como disponibles. |
| HU-05e | Cierre automático de préstamos no recogidos | ENCARGADO | Must | Evita unidades reservadas indefinidamente para quien no llegó; sin ello el stock se bloquea. |
| SH-02 | Marcado de préstamos vencidos | ENCARGADO | Should | Con HU-05a a HU-05e ya se presta y se recupera; marcar vencidos es control posterior y las Must no dependen de él. |
| SH-03 | Sanciones por retraso | ENCARGADO | Should | Disuade retrasos, pero el sistema cumple su propósito de prestar sin sancionar. |
| SH-06 | Alerta de préstamo próximo a vencer | ESTUDIANTE | Should | Mejora el cumplimiento de plazos; el ciclo funciona sin ella (su beneficio se apoya en SH-03). |
| SH-07 | Cancelar mi solicitud | ESTUDIANTE | Should | Libera unidades reservadas sin intervención del encargado; el ciclo funciona sin ello. |
| SH-01 | Historial "Mis préstamos" | ESTUDIANTE | Should | El estudiante ya ve el estado de sus solicitudes en HU-04; esta historia solo añade filtros por estado y fechas. |
| SH-04 | Panel de métricas | ADMIN | Should | Apoya decisiones de compra; no es operativo. |
| SH-05 | Exportación a CSV | ENCARGADO | Should | Útil para reportes; existen alternativas manuales. |
| SH-11 | Bloqueo temporal por intentos fallidos | Todos los roles | Should | Protege las cuentas de adivinación de contraseñas; el préstamo funciona sin ello. |
| SH-09 | Duración y expiración de la sesión | Todos los roles | Should | Evita que otra persona use una cuenta abierta en un equipo compartido; no bloquea el préstamo. |
| SH-08 | Baja de cuentas | ADMIN | Should | Quita el acceso a quien ya no pertenece a la institución sin perder historial; sin ello la cuenta sigue activa. Depende de SH-09 (corte de sesiones abiertas). |
| SH-10 | Sesión única por usuario | Todos los roles | Should | Decisión tomada del usuario (recogida en `CLAUDE.md`); da control de que nadie más usa la cuenta, sin bloquear el préstamo. |
| SH-12 | Cierre de la sesión de otra cuenta por el ADMIN | ADMIN | Should | Permite proteger una cuenta si se pierde un dispositivo; el ciclo del préstamo no depende de ello. |

---

## Must

### HU-01a · Registro de cuenta de estudiante
**Prioridad:** Must
**Historia:** Como ESTUDIANTE quiero registrarme con mi correo institucional para que mis préstamos queden a mi nombre y la institución sepa quién es responsable de cada equipo.

**Reglas de negocio**
- RN-01a.1 El correo debe terminar en "@institucion.edu".
- RN-01a.2 El correo no puede estar ya registrado. El registro puede indicar que ya existe una cuenta asociada a ese correo; es una limitación aceptada por el usuario y no aplica al inicio de sesión (PA-34).
- RN-01a.3 La contraseña tiene al menos 8 caracteres con al menos una letra y un número.
- RN-01a.4 Toda cuenta registrada por esta vía tiene el rol ESTUDIANTE; no existe forma de elegir otro rol al registrarse. Los ENCARGADO y ADMIN los provee la institución mediante una carga inicial de cuentas, con al menos un ADMIN existente desde el inicio.

**Criterios de aceptación**
**Escenario 1: Registro correcto**
- Given que no existe cuenta con el correo "ana@institucion.edu"
- When me registro con ese correo y la contraseña "Clave2024" (RN-01a.1, RN-01a.3)
- Then se crea mi cuenta con rol ESTUDIANTE (RN-01a.4)

**Escenario 2: Correo ya registrado**
- Given que existe una cuenta con "ana@institucion.edu"
- When intento registrarme con ese correo (RN-01a.2)
- Then se rechaza con el mensaje "Ya existe una cuenta asociada a ese correo"

**Escenario 3: Correo no institucional**
- Given que no existe cuenta con "ana@gmail.com"
- When intento registrarme con ese correo (RN-01a.1)
- Then se rechaza con el mensaje "Usa tu correo institucional"

**Escenario 4: Contraseña que no cumple**
- Given un correo institucional libre
- When me registro con la contraseña "abc123" (6 caracteres) (RN-01a.3)
- Then se rechaza con el mensaje "La contraseña debe tener al menos 8 caracteres, una letra y un número"

**Escenario 5: Sin elección de rol**
- Given que completé el registro correctamente
- When consulto el rol de mi cuenta (RN-01a.4)
- Then mi rol es ESTUDIANTE y no tengo opciones de ENCARGADO ni de ADMIN

### HU-01b · Inicio de sesión y acceso según rol
**Prioridad:** Must
**Historia:** Como ESTUDIANTE, ENCARGADO o ADMIN quiero iniciar sesión y acceder solo a las funciones de mi rol para que cada persona opere únicamente lo que le corresponde y el inventario esté protegido.

**Reglas de negocio**
- RN-01b.1 Con credenciales correctas se accede a las funciones del rol de la cuenta.
- RN-01b.2 Regla general: ningún mensaje de inicio de sesión o de bloqueo revela si un correo existe ni si un dato (correo o contraseña) es correcto. Credenciales incorrectas, cuenta inexistente, cuenta dada de baja y cuenta bloqueada por intentos devuelven el mismo mensaje "Credenciales inválidas" y no dan acceso.
- RN-01b.3 Un usuario sin sesión no accede a ninguna función de la aplicación salvo registro e inicio de sesión.
- RN-01b.4 Un usuario solo ejecuta acciones de su rol; las demás se rechazan con "Acceso denegado".
- RN-01b.5 La duración de la sesión, la sesión única por usuario y el bloqueo por intentos fallidos se describen en historias propias (SH-09, SH-10 y SH-11) para que esta historia siga siendo pequeña; ninguna de ellas es requisito para HU-01b.

**Criterios de aceptación**
**Escenario 1: Inicio de sesión correcto**
- Given una cuenta ESTUDIANTE "ana@institucion.edu"
- When inicio sesión con sus credenciales correctas (RN-01b.1)
- Then accedo a las funciones de ESTUDIANTE

**Escenario 2: Credenciales incorrectas**
- Given una cuenta existente
- When inicio sesión con contraseña equivocada (RN-01b.2)
- Then no accedo y veo el mensaje "Credenciales inválidas"

**Escenario 2b: Correo que no existe**
- Given que no existe ninguna cuenta con "nadie@institucion.edu"
- When inicio sesión con ese correo y cualquier contraseña (RN-01b.2)
- Then no accedo y veo exactamente el mismo mensaje "Credenciales inválidas"

**Escenario 3: Acción de otro rol**
- Given que inicié sesión como ESTUDIANTE
- When intento ejecutar una acción reservada a ENCARGADO (RN-01b.4)
- Then veo el mensaje "Acceso denegado"

**Escenario 4: Sin sesión**
- Given que no he iniciado sesión
- When intento ejecutar cualquier función protegida (RN-01b.3)
- Then se me pide iniciar sesión y no veo datos

**Escenario 5: Cuenta ADMIN inicial**
- Given la cuenta ADMIN provista por la institución
- When inicio sesión con sus credenciales (RN-01b.1)
- Then accedo a las funciones de ADMIN

### HU-02a · Crear y editar equipos del catálogo
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero crear y editar equipos con categoría, código de inventario, unidades y estado para que los estudiantes vean un catálogo real y actualizado.

**Reglas de negocio**
- RN-02a.1 Todo equipo tiene nombre, categoría, código de inventario, unidades totales y estado.
- RN-02a.2 El código de inventario es único en todo el catálogo, incluidos los equipos dados de baja.
- RN-02a.3 Al crear o al editar manualmente, las unidades totales son un entero mayor o igual a 1. Solo una devolución con equipos DAÑADO o PERDIDO (HU-05d) puede dejar el total en 0.
- RN-02a.4 El estado del equipo es DISPONIBLE o MANTENIMIENTO. Un equipo en MANTENIMIENTO se muestra como "No disponible", no admite nuevas solicitudes y no afecta los préstamos ya APROBADO, ENTREGADO o VENCIDO.
- RN-02a.5 Unidades comprometidas de un equipo = máximo, entre todos los días desde hoy en adelante, de las unidades retenidas ese día por préstamos activos (ver convenciones).
- RN-02a.6 En la edición manual, las unidades totales no pueden reducirse por debajo de las unidades comprometidas. Esta regla no aplica a la reducción automática por devolución (HU-05d, RN-05d.3 y RN-05d.4).
- RN-02a.7 Solo ENCARGADO y ADMIN gestionan el catálogo.

**Criterios de aceptación**
**Escenario 1: Crear un equipo**
- Given que soy ENCARGADO
- When registro "Portátil Lenovo" con código "LAB-001", categoría "Cómputo", 5 unidades y estado DISPONIBLE (RN-02a.1)
- Then el equipo aparece en el catálogo con 5 unidades

**Escenario 2: Código duplicado**
- Given que existe un equipo con código "LAB-001"
- When intento crear otro con código "LAB-001" (RN-02a.2)
- Then se rechaza con el mensaje "El código de inventario ya existe"

**Escenario 3: Unidades menores a 1**
- Given que soy ENCARGADO
- When intento crear un equipo con 0 unidades (RN-02a.3)
- Then se rechaza con el mensaje "Las unidades deben ser al menos 1"

**Escenario 4: Reducir unidades por debajo de lo comprometido**
- Given que hoy es 1 de noviembre y un equipo de 5 unidades con un préstamo APROBADO de 3 unidades del 10 al 12 de noviembre (3 unidades comprometidas)
- When edito las unidades totales a 2 (RN-02a.5, RN-02a.6)
- Then se rechaza con el mensaje "Hay 3 unidades comprometidas"

**Escenario 5: Equipo en mantenimiento**
- Given un equipo DISPONIBLE sin préstamos
- When cambio su estado a MANTENIMIENTO (RN-02a.4)
- Then el catálogo lo muestra como "No disponible"

**Escenario 6: Permisos**
- Given que soy ESTUDIANTE
- When intento crear un equipo (RN-02a.7)
- Then veo el mensaje "Acceso denegado"

### HU-02b · Dar de baja un equipo
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero dar de baja un equipo que ya no se usa para que deje de ofrecerse sin perder el historial de sus préstamos.

**Reglas de negocio**
- RN-02b.1 La baja es lógica: el equipo y su historial se conservan, pero deja de aparecer en el catálogo y en las búsquedas.
- RN-02b.2 No se puede dar de baja un equipo con préstamos activos (ver convenciones). Un APROBADO no recogido deja de bloquear cuando el sistema lo cierra como RECHAZADO (HU-05e, RN-05e.1) o cuando el estudiante lo cancela (SH-07).
- RN-02b.3 Si el equipo tiene solicitudes en estado SOLICITADO, estas se rechazan automáticamente con el motivo "Equipo dado de baja" y el equipo se da de baja. Una solicitud con varios equipos se rechaza completa. Este motivo propio prevalece sobre el "Sin resolver a tiempo" de RN-05a.11, que solo se usa cuando la solicitud llega a su día de inicio sin ninguna otra resolución.
- RN-02b.4 Un equipo dado de baja no puede solicitarse.
- RN-02b.5 Solo ENCARGADO y ADMIN dan de baja equipos.

**Criterios de aceptación**
**Escenario 1: Baja correcta**
- Given un equipo sin préstamos activos ni solicitudes
- When lo doy de baja (RN-02b.1)
- Then desaparece del catálogo y sus préstamos DEVUELTO anteriores siguen existiendo

**Escenario 2: Baja con préstamo activo**
- Given un equipo con un préstamo ENTREGADO
- When intento darlo de baja (RN-02b.2)
- Then se rechaza con el mensaje "El equipo tiene préstamos activos"

**Escenario 3: Baja con solicitud pendiente**
- Given un equipo con una solicitud SOLICITADO de un estudiante
- When lo doy de baja (RN-02b.3)
- Then la solicitud pasa a RECHAZADO con el motivo "Equipo dado de baja"

**Escenario 4: Solicitar un equipo dado de baja**
- Given un equipo dado de baja
- When un estudiante intenta solicitarlo (RN-02b.4)
- Then se rechaza con el mensaje "Equipo no disponible"

**Escenario 5: Solicitud con varios equipos que incluye uno dado de baja**
- Given el equipo A con unidades disponibles y el equipo B dado de baja
- When un estudiante envía una solicitud con A y B (RN-02b.4)
- Then se rechaza con el mensaje "Equipo no disponible" y no se crea ninguna solicitud

**Escenario 6: Permisos**
- Given que soy ESTUDIANTE
- When intento dar de baja un equipo (RN-02b.5)
- Then veo el mensaje "Acceso denegado"

### HU-03 · Consulta de disponibilidad
**Prioridad:** Must
**Historia:** Como ESTUDIANTE quiero buscar equipos por nombre o categoría y ver las unidades disponibles en un rango de fechas para saber si puedo pedirlos antes de ir al laboratorio.

**Reglas de negocio**
- RN-03.1 La búsqueda por nombre es por coincidencia parcial sin distinguir mayúsculas ("cámara" encuentra "Cámara Canon EOS R10"); la búsqueda por categoría es por categoría exacta.
- RN-03.2 Disponibilidad en un rango = unidades totales menos unidades retenidas por los préstamos cuyo rango efectivo de retención (convenciones, PA-28) se cruza con el rango consultado. Un APROBADO retiene hasta el día en que vence su plazo de recogida o su fecha fin, el que sea posterior; un ENTREGADO o VENCIDO retiene hasta que se devuelva: cubre su rango y, si su fecha fin ya pasó, cada día desde hoy hasta su devolución, por lo que descuenta en todo rango que incluya hoy o fechas posteriores hasta que pase a DEVUELTO. La disponibilidad nunca se muestra negativa (mínimo 0).
- RN-03.3 Los préstamos SOLICITADO, RECHAZADO, CANCELADO y DEVUELTO no retienen unidades.
- RN-03.4 Los equipos dados de baja no aparecen; los equipos en MANTENIMIENTO aparecen como "No disponible".
- RN-03.5 El rango debe cumplir las convenciones comunes: máximo 7 días, fin no anterior a inicio, inicio no anterior a hoy. Si no se cumple, no se ejecuta la búsqueda.

**Criterios de aceptación**
**Escenario 1: Unidades disponibles**
- Given el equipo "Cámara Canon EOS R10" con 3 unidades y 1 en un préstamo APROBADO del 10 al 12 de noviembre
- When busco "cámara" para el rango del 11 al 13 de noviembre (RN-03.1, RN-03.2)
- Then veo "Cámara Canon EOS R10" con 2 unidades disponibles

**Escenario 2: Fin de un préstamo e inicio del rango el mismo día**
- Given un equipo con 3 unidades y 1 en un préstamo APROBADO del 8 al 12 de noviembre
- When consulto el rango del 12 al 14 de noviembre (RN-03.2)
- Then veo 2 unidades disponibles

**Escenario 3: Solicitudes pendientes no retienen**
- Given un equipo con 5 unidades y una solicitud SOLICITADO de 2 en el mismo rango
- When consulto el rango (RN-03.3)
- Then veo 5 unidades disponibles

**Escenario 4: Préstamo con fecha fin pasada sin devolver retiene unidades**
- Given que hoy es 15 de noviembre y un equipo con 5 unidades con un préstamo ENTREGADO de 2 unidades, fecha fin 13 de noviembre, sin devolver
- When consulto el rango del 16 al 18 de noviembre (RN-03.2)
- Then veo 3 unidades disponibles

**Escenario 4b: Disponibilidad nunca negativa**
- Given un equipo cuyo total bajó a 1 unidad y que tiene 2 unidades retenidas por préstamos APROBADO en el rango
- When consulto ese rango (RN-03.2)
- Then veo 0 unidades disponibles

**Escenario 4c: Aprobado cuyo plazo de recogida llega al día siguiente**
- Given un equipo de 1 unidad y un préstamo APROBADO del 10 al 10 de noviembre aprobado a las 5:00 PM del 10 (plazo hasta las 10:00 AM del 11)
- When consulto el rango del 11 al 11 de noviembre (RN-03.2)
- Then veo 0 unidades disponibles

**Escenario 5: Búsqueda por categoría**
- Given 2 equipos de la categoría "Audiovisual" y 1 de "Cómputo"
- When filtro por la categoría "Audiovisual" (RN-03.1)
- Then veo solo los 2 equipos de "Audiovisual"

**Escenario 6: Equipos no prestables**
- Given un equipo en MANTENIMIENTO y otro dado de baja
- When busco en el catálogo (RN-03.4)
- Then el de mantenimiento se muestra como "No disponible" y el dado de baja no aparece

**Escenario 7: Rango de 8 días**
- Given que elijo del 10 al 17 de noviembre (8 días)
- When realizo la consulta (RN-03.5)
- Then veo el mensaje "El rango máximo es de 7 días" y no se ejecuta la búsqueda

**Escenario 8: Rango invertido**
- Given que elijo fecha inicio 12 de noviembre y fecha fin 10 de noviembre
- When realizo la consulta (RN-03.5)
- Then veo el mensaje "La fecha fin no puede ser anterior a la fecha inicio"

**Escenario 9: Fecha pasada**
- Given que hoy es 15 de noviembre y elijo inicio el 14 de noviembre
- When realizo la consulta (RN-03.5)
- Then veo el mensaje "La fecha de inicio no puede ser anterior a hoy"

### HU-04 · Solicitud de préstamo
**Prioridad:** Must
**Historia:** Como ESTUDIANTE quiero solicitar uno o varios equipos para un rango de hasta 7 días para disponer de ellos en mis prácticas sin ir presencialmente a pedirlos.

**Reglas de negocio**
- RN-04.1 Una solicitud incluye uno o más equipos, cada uno con cantidad mayor o igual a 1.
- RN-04.2 El rango cumple las convenciones comunes: máximo 7 días, fin no anterior a inicio, inicio no anterior a hoy. Se permite solicitar con inicio el mismo día (antelación mínima 0 días, PA-4).
- RN-04.3 La cantidad pedida de cada equipo no supera su disponibilidad en el rango.
- RN-04.4 La solicitud se registra completa o no se registra: si un equipo no tiene unidades suficientes, no se registra ninguna parte.
- RN-04.5 Toda solicitud nace en estado SOLICITADO y no retiene unidades hasta ser aprobada. La competencia por las últimas unidades se resuelve al aprobar (HU-05a).
- RN-04.6 No se puede solicitar un equipo en MANTENIMIENTO ni dado de baja.
- RN-04.7 El estudiante ve sus solicitudes con su estado actual y, si están en RECHAZADO, el motivo. Los filtros por estado y fechas son de SH-01.
- RN-04.8 Un estudiante no puede tener más de 3 préstamos en curso (SOLICITADO, APROBADO, ENTREGADO o VENCIDO) a la vez (PA-10). Una solicitud con varios equipos cuenta como 1 préstamo. Al llegar al límite, la solicitud se rechaza con "Ya tienes 3 préstamos en curso". Si SH-03 lo bloquea, aplica además lo que indica esa historia.

**Criterios de aceptación**
**Escenario 1: Solicitud correcta**
- Given que hoy es 1 de noviembre y un equipo con 3 unidades disponibles del 10 al 12 de noviembre
- When solicito 2 unidades para ese rango (RN-04.1, RN-04.5)
- Then se crea la solicitud en estado SOLICITADO

**Escenario 2: Unidades insuficientes**
- Given un equipo con 1 unidad disponible en el rango
- When solicito 2 unidades (RN-04.3)
- Then veo el mensaje "Unidades insuficientes" con la cantidad disponible y no se crea la solicitud

**Escenario 3: Rango de 8 días**
- Given que elijo del 10 al 17 de noviembre (8 días)
- When envío la solicitud (RN-04.2)
- Then veo el mensaje "El rango máximo es de 7 días"

**Escenario 4: Rango de 7 días**
- Given un equipo con unidades disponibles del 10 al 16 de noviembre
- When envío la solicitud para ese rango de 7 días (RN-04.2)
- Then se crea la solicitud en estado SOLICITADO

**Escenario 5: Fecha fin anterior a inicio**
- Given que elijo inicio el 12 de noviembre y fin el 10 de noviembre
- When envío la solicitud (RN-04.2)
- Then veo el mensaje "La fecha fin no puede ser anterior a la fecha inicio"

**Escenario 6: Inicio en el pasado**
- Given que hoy es 15 de noviembre y elijo inicio el 14 de noviembre
- When envío la solicitud (RN-04.2)
- Then veo el mensaje "La fecha de inicio no puede ser anterior a hoy"

**Escenario 7: Varios equipos y uno sin unidades**
- Given que pido el equipo A (con unidades) y el B (sin unidades) para el mismo rango
- When envío la solicitud (RN-04.4)
- Then no se crea ninguna solicitud y se indica que B tiene "Unidades insuficientes"

**Escenario 8: Equipo en mantenimiento**
- Given un equipo en MANTENIMIENTO
- When lo solicito (RN-04.6)
- Then veo el mensaje "Equipo no disponible" y no se crea la solicitud

**Escenario 9: Cantidad 0**
- Given un equipo con unidades disponibles
- When solicito 0 unidades (RN-04.1)
- Then veo el mensaje "La cantidad debe ser al menos 1" y no se crea la solicitud

**Escenario 10: Ver el estado de mi solicitud**
- Given una solicitud mía en estado SOLICITADO
- When abro la lista de mis solicitudes (RN-04.7)
- Then veo la solicitud con el estado SOLICITADO

**Escenario 11: Ver el motivo de un rechazo**
- Given una solicitud mía RECHAZADO con motivo "Equipo reservado para examen"
- When abro su detalle (RN-04.7)
- Then veo el estado RECHAZADO y el motivo

**Escenario 12: El tercer préstamo en curso se permite**
- Given que tengo 2 préstamos en curso y un equipo con unidades disponibles
- When envío una solicitud válida (RN-04.8)
- Then se crea la solicitud en estado SOLICITADO y tengo 3 préstamos en curso

**Escenario 13: El cuarto préstamo en curso se bloquea**
- Given que tengo 3 préstamos en curso (por ejemplo 1 SOLICITADO, 1 APROBADO y 1 ENTREGADO)
- When envío una solicitud válida (RN-04.8)
- Then se rechaza con el mensaje "Ya tienes 3 préstamos en curso" y no se crea la solicitud

**Escenario 14: Un préstamo devuelto libera cupo**
- Given que tenía 3 préstamos en curso y uno pasó a DEVUELTO
- When envío una solicitud válida (RN-04.8)
- Then se crea la solicitud en estado SOLICITADO

**Escenario 15: Una solicitud rechazada libera cupo**
- Given que tenía 3 préstamos en curso y una solicitud mía pasó a RECHAZADO (por ejemplo, "Sin resolver a tiempo")
- When envío una solicitud válida (RN-04.8)
- Then se crea la solicitud en estado SOLICITADO

**Escenario 16: Una solicitud cancelada libera cupo**
- Given que tenía 3 préstamos en curso y una solicitud mía pasó a CANCELADO
- When envío una solicitud válida (RN-04.8)
- Then se crea la solicitud en estado SOLICITADO

### HU-05a · Aprobar o rechazar solicitudes
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero aprobar o rechazar solicitudes pendientes para controlar qué equipos salen y reservar las unidades de los préstamos aceptados.

**Reglas de negocio**
- RN-05a.1 Solo una solicitud en estado SOLICITADO puede aprobarse o rechazarse. Un préstamo ya APROBADO no se rechaza.
- RN-05a.2 Rechazar exige un motivo de entre 10 y 250 caracteres que el estudiante puede ver.
- RN-05a.3 Al aprobar se comprueba la disponibilidad actual del rango para cada equipo, calculada con el total vigente del equipo (incluidas las unidades restadas por devoluciones DAÑADO o PERDIDO) y con todos los préstamos cuyo rango efectivo de retención (convenciones) se cruza con el rango efectivo que tendría la solicitud al aprobarse ahora (desde su inicio hasta el día en que vencería su plazo de recogida o su fecha fin, el que sea posterior); si no alcanza, la aprobación se bloquea con "Unidades insuficientes". Es la única barrera: una vez APROBADO, el préstamo no se rechaza.
- RN-05a.4 Al aprobar queda registrado quién y cuándo, y las unidades quedan retenidas.
- RN-05a.5 Un préstamo RECHAZADO no retiene unidades.
- RN-05a.6 Solo ENCARGADO y ADMIN aprueban o rechazan.
- RN-05a.7 No se aprueba una solicitud que incluya un equipo en MANTENIMIENTO; sí puede rechazarse. (Las solicitudes de un equipo dado de baja ya se rechazan solas, HU-02b.)
- RN-05a.8 No se aprueba una solicitud cuya fecha de inicio es anterior a hoy; sí puede rechazarse. Si la fecha de fin ya pasó, el mensaje es "La solicitud ya terminó"; si la fecha de inicio pasó pero la de fin no, es "La solicitud ya inició". Una solicitud con inicio hoy sí puede aprobarse, con el plazo de recogida de las convenciones.
- RN-05a.9 El pase de un APROBADO no recogido a RECHAZADO lo hace el sistema (HU-05e, RN-05e.1), no el encargado.
- RN-05a.10 Las aprobaciones solo se hacen en horario de servicio, de 8:00 AM a 5:00 PM (ambas horas incluidas). Fuera de ese horario se bloquean con "Las aprobaciones se hacen de 8:00 AM a 5:00 PM".
- RN-05a.11 Una solicitud SOLICITADO que llega al día siguiente de su fecha de inicio sin haberse aprobado ni rechazado se rechaza automáticamente en la revisión de las 00:05 con el motivo "Sin resolver a tiempo", y el estudiante recibe un aviso en la aplicación. Así deja de ocupar un cupo del límite de 3 (HU-04). (confirmado, PA-27).
- RN-05a.12 La aprobación no se bloquea porque el plazo de recogida sobrepase la fecha fin del préstamo (confirmado, PA-22): un préstamo de 1 día aprobado después de las 3:00 PM tiene plazo hasta las 10:00 AM del día siguiente.

**Criterios de aceptación**
**Escenario 1: Aprobar**
- Given una solicitud SOLICITADO de 2 unidades de un equipo con 3 disponibles
- When la apruebo (RN-05a.3, RN-05a.4)
- Then pasa a APROBADO con mi nombre y la hora, y la disponibilidad del rango baja a 1 unidad

**Escenario 2: Rechazar con motivo**
- Given una solicitud SOLICITADO
- When la rechazo con el motivo "Equipo reservado para examen" (RN-05a.2, RN-05a.5)
- Then pasa a RECHAZADO y el motivo queda guardado para que el estudiante lo vea en su solicitud (HU-04, RN-04.7)

**Escenario 3: Rechazar sin motivo suficiente**
- Given una solicitud SOLICITADO
- When intento rechazarla con el motivo "No" (menos de 10 caracteres) (RN-05a.2)
- Then veo el mensaje "El motivo debe tener entre 10 y 250 caracteres" y la solicitud sigue SOLICITADO

**Escenario 4: Competencia por la última unidad**
- Given un equipo con 1 unidad, una solicitud A ya aprobada para el rango y una solicitud B SOLICITADO de 1 unidad para el mismo rango
- When intento aprobar B (RN-05a.3)
- Then se bloquea con "Unidades insuficientes", B sigue SOLICITADO y A sigue APROBADO

**Escenario 5: Unidades comprometidas por otras aprobaciones**
- Given un equipo con 3 unidades, 2 retenidas por préstamos APROBADO en el rango y una solicitud SOLICITADO de 2 unidades
- When intento aprobarla (RN-05a.3)
- Then se bloquea con "Unidades insuficientes" y sigue SOLICITADO

**Escenario 6: Solicitud que no está pendiente**
- Given un préstamo en estado RECHAZADO
- When intento aprobarlo (RN-05a.1)
- Then veo el mensaje "Solo se resuelven solicitudes pendientes" y el estado no cambia

**Escenario 7: Permisos**
- Given que inicié sesión como ESTUDIANTE
- When intento aprobar una solicitud (RN-05a.6)
- Then veo el mensaje "Acceso denegado"

**Escenario 8: Equipo en mantenimiento**
- Given una solicitud SOLICITADO de un equipo que ahora está en MANTENIMIENTO
- When intento aprobarla (RN-05a.7)
- Then se bloquea con el mensaje "Equipo no disponible" y sigue SOLICITADO

**Escenario 9: Rango ya terminado**
- Given que hoy es 15 de noviembre y una solicitud SOLICITADO del 10 al 12 de noviembre
- When intento aprobarla (RN-05a.8)
- Then se bloquea con el mensaje "La solicitud ya terminó" y sigue SOLICITADO

**Escenario 10: Rango ya iniciado**
- Given que hoy es 11 de noviembre y una solicitud SOLICITADO del 10 al 12 de noviembre
- When intento aprobarla (RN-05a.8)
- Then se bloquea con el mensaje "La solicitud ya inició" y sigue SOLICITADO

**Escenario 11: Aprobación fuera de horario**
- Given que son las 5:01 PM y una solicitud SOLICITADO con inicio mañana
- When intento aprobarla (RN-05a.10)
- Then se bloquea con el mensaje "Las aprobaciones se hacen de 8:00 AM a 5:00 PM" y sigue SOLICITADO

**Escenario 12: Aprobación a las 5:00 PM exactas**
- Given que son las 5:00 PM y una solicitud SOLICITADO con inicio mañana y disponibilidad suficiente
- When la apruebo (RN-05a.10)
- Then pasa a APROBADO

**Escenario 13: Un aprobado no se rechaza**
- Given un préstamo APROBADO
- When intento rechazarlo con el motivo "Equipo ya no disponible" (RN-05a.1)
- Then veo el mensaje "Solo se resuelven solicitudes pendientes" y sigue APROBADO

**Escenario 14: Aprobación a las 3:01 PM de un préstamo de 1 día**
- Given que hoy es 10 de noviembre, son las 3:01 PM y una solicitud SOLICITADO del 10 al 10 de noviembre (1 día) con disponibilidad suficiente
- When la apruebo (RN-05a.12)
- Then pasa a APROBADO con plazo de recogida hasta las 10:00 AM del 11 de noviembre

**Escenario 15: Aprobación a las 5:00 PM de un préstamo de 1 día**
- Given que hoy es 10 de noviembre, son las 5:00 PM y una solicitud SOLICITADO del 10 al 10 de noviembre (1 día) con disponibilidad suficiente
- When la apruebo (RN-05a.12)
- Then pasa a APROBADO con plazo de recogida hasta las 10:00 AM del 11 de noviembre

**Escenario 16: Solicitud sin resolver tras su fecha de inicio**
- Given una solicitud SOLICITADO con inicio el 10 de noviembre que nadie aprobó ni rechazó
- When el sistema realiza la revisión de las 00:05 del 11 de noviembre (RN-05a.11)
- Then pasa a RECHAZADO con el motivo "Sin resolver a tiempo" y el estudiante recibe un aviso con ese motivo

**Escenario 17: Retención del plazo que cruza al día siguiente**
- Given un equipo de 1 unidad, un préstamo B APROBADO para el 11 de noviembre y una solicitud A SOLICITADO para el 10 de noviembre (1 día), a las 5:00 PM del 10
- When intento aprobar A (RN-05a.3)
- Then se bloquea con "Unidades insuficientes", porque A retendría la unidad hasta el 11 y se cruza con B

**Escenario 18: Aprobación cuyo plazo no cruza al día siguiente**
- Given el mismo equipo de 1 unidad y el préstamo B APROBADO para el 11 de noviembre, a las 3:00 PM del 10, y A SOLICITADO para el 10 (1 día)
- When apruebo A (RN-05a.3)
- Then pasa a APROBADO con plazo hasta las 5:00 PM del 10, sin cruzarse con B

### HU-05b · Registrar la entrega
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero registrar la entrega de un préstamo aprobado para saber quién tiene cada equipo y desde cuándo.

**Reglas de negocio**
- RN-05b.1 Solo un préstamo APROBADO pasa a ENTREGADO.
- RN-05b.2 La entrega registra fecha, hora y el encargado que la realizó.
- RN-05b.3 La entrega solo se permite dentro del plazo de recogida definido en las convenciones. El plazo empieza a las 8:00 AM del día de inicio o en la hora de aprobación si es posterior, y puede cruzar al día siguiente aunque la fecha fin ya haya pasado (por ejemplo, una aprobación a las 4:00 PM del día de inicio da plazo hasta las 9:00 AM del día siguiente; un préstamo de 1 día aprobado a las 5:00 PM, hasta las 10:00 AM del día siguiente). Antes de las 8:00 AM del día de inicio o en un día anterior no se permite. Una entrega posterior a la fecha fin deja el préstamo ENTREGADO con fecha fin efectiva igual al día de la entrega (convenciones, PA-25).
- RN-05b.4 Un préstamo ENTREGADO sigue reteniendo unidades hasta su devolución.
- RN-05b.5 Solo ENCARGADO y ADMIN registran entregas.
- RN-05b.6 No se entrega un préstamo si el total actual del equipo no cubre la cantidad prestada; se bloquea con "Unidades insuficientes". El préstamo queda APROBADO hasta que venza su plazo (HU-05e) (confirmado, PA-20).

**Criterios de aceptación**
**Escenario 1: Entrega correcta**
- Given que hoy es 10 de noviembre, son las 8:30 AM y un préstamo APROBADO del 10 al 12 de noviembre
- When registro la entrega (RN-05b.1, RN-05b.2, RN-05b.3)
- Then pasa a ENTREGADO con fecha, hora y mi nombre

**Escenario 2: Préstamo no aprobado**
- Given un préstamo SOLICITADO
- When intento registrar su entrega (RN-05b.1)
- Then veo el mensaje "Solo se entregan préstamos aprobados" y el estado no cambia

**Escenario 3: Entrega antes del inicio**
- Given que hoy es 5 de noviembre y un préstamo APROBADO del 10 al 12 de noviembre
- When intento registrar la entrega (RN-05b.3)
- Then veo el mensaje "El préstamo aún no inicia"

**Escenario 4: Entrega antes del inicio de servicio**
- Given que hoy es 10 de noviembre, son las 7:59 AM y un préstamo APROBADO del 10 al 12 de noviembre
- When intento registrar la entrega (RN-05b.3)
- Then veo el mensaje "El servicio inicia a las 8:00 AM"

**Escenario 5: Entrega pasadas las 10:00 AM**
- Given que hoy es 10 de noviembre, son las 10:00 AM y un préstamo APROBADO del 10 al 12 de noviembre ya cerrado como RECHAZADO "No recogido"
- When intento registrar la entrega (RN-05b.1)
- Then veo el mensaje "Solo se entregan préstamos aprobados" y el estado no cambia

**Escenario 6: Permisos**
- Given que inicié sesión como ESTUDIANTE
- When intento registrar una entrega (RN-05b.5)
- Then veo el mensaje "Acceso denegado"

**Escenario 7: Las unidades siguen retenidas tras la entrega**
- Given que hoy es 10 de noviembre, son las 8:30 AM, un equipo de 5 unidades y un préstamo APROBADO de 2 unidades del 10 al 12 de noviembre
- When registro la entrega (RN-05b.4)
- Then pasa a ENTREGADO y la disponibilidad del rango del 10 al 12 de noviembre sigue en 3 unidades

**Escenario 8: A las 9:59 AM aún se puede entregar**
- Given que hoy es 10 de noviembre, son las 9:59 AM y un préstamo APROBADO del 10 al 12 de noviembre aprobado días antes y sin entregar
- When registro la entrega (RN-05b.3)
- Then pasa a ENTREGADO

**Escenario 9: Entrega a las 12:00 PM tras aprobación a las 11:00 AM**
- Given que hoy es 10 de noviembre, un préstamo con inicio hoy aprobado a las 11:00 AM (plazo hasta la 1:00 PM) y son las 12:00 PM
- When registro la entrega (RN-05b.3)
- Then pasa a ENTREGADO

**Escenario 10: Entrega al día siguiente dentro del plazo (préstamo de varios días)**
- Given que hoy es 11 de noviembre, son las 8:30 AM y un préstamo del 10 al 12 de noviembre aprobado el 10 de noviembre a las 4:00 PM (plazo hasta las 9:00 AM de hoy)
- When registro la entrega (RN-05b.3)
- Then pasa a ENTREGADO

**Escenario 11: Entrega al día siguiente de la fecha fin**
- Given que hoy es 11 de noviembre, son las 8:30 AM y un préstamo del 10 al 10 de noviembre aprobado el 10 de noviembre a las 5:00 PM
- When registro la entrega (RN-05b.3)
- Then pasa a ENTREGADO con fecha fin efectiva el 11 de noviembre

**Escenario 12: Total del equipo que no cubre la cantidad**
- Given que son las 9:00 AM del día de inicio y un préstamo APROBADO de 2 unidades de un equipo cuyo total bajó a 1 por una devolución con unidades PERDIDO
- When intento registrar la entrega (RN-05b.6)
- Then se bloquea con el mensaje "Unidades insuficientes" y el estado no cambia

### HU-05c · Registrar la devolución
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero registrar la devolución de un préstamo cuyas unidades vuelven útiles para cerrar el préstamo y que esas unidades queden disponibles de inmediato.

**Reglas de negocio**
- RN-05c.1 Solo un préstamo ENTREGADO o VENCIDO pasa a DEVUELTO (la transición VENCIDO -> DEVUELTO está confirmada, PA-14).
- RN-05c.2 Al devolver, por cada equipo del préstamo el encargado indica cuántas unidades quedan en cada estado: BUENO, CON_DESPERFECTOS, DAÑADO o PERDIDO (PA-6). La suma debe igualar las unidades prestadas de ese equipo. Esta historia cubre devoluciones solo con BUENO y CON_DESPERFECTOS; con DAÑADO o PERDIDO aplica HU-05d.
- RN-05c.3 Si alguna unidad queda en CON_DESPERFECTOS, la observación es obligatoria.
- RN-05c.4 Las unidades BUENO o CON_DESPERFECTOS vuelven a estar disponibles de inmediato.
- RN-05c.5 La devolución queda registrada con fecha, hora y encargado.
- RN-05c.6 Solo ENCARGADO y ADMIN registran devoluciones.
- RN-05c.7 Los casos de préstamos en estado VENCIDO de esta historia aplican cuando exista SH-02; sin él, el mismo comportamiento se da en un ENTREGADO con fecha fin pasada.

**Criterios de aceptación**
**Escenario 1: Devolución en buen estado**
- Given un equipo con 5 unidades y un préstamo ENTREGADO de 2 unidades
- When registro la devolución con las 2 unidades en estado BUENO (RN-05c.1, RN-05c.4, RN-05c.5)
- Then pasa a DEVUELTO con fecha, hora y mi nombre, y las 5 unidades quedan disponibles

**Escenario 2: Unidades con desperfectos**
- Given un equipo con 5 unidades y un préstamo ENTREGADO de 2 unidades
- When registro la devolución con 1 unidad BUENO y 1 unidad CON_DESPERFECTOS con la observación "Rayón en la carcasa" (RN-05c.2, RN-05c.4)
- Then pasa a DEVUELTO y quedan las 5 unidades disponibles

**Escenario 3: CON_DESPERFECTOS sin observación**
- Given un préstamo ENTREGADO
- When registro la devolución con una unidad CON_DESPERFECTOS y sin observación (RN-05c.3)
- Then veo el mensaje "La observación es obligatoria" y el estado no cambia

**Escenario 3b: Cantidades que no suman**
- Given un préstamo ENTREGADO de 2 unidades
- When registro la devolución con 1 unidad BUENO y ninguna otra (RN-05c.2)
- Then veo el mensaje "Las unidades indicadas no coinciden con las prestadas" y el estado no cambia

**Escenario 4: Préstamo no entregado**
- Given un préstamo APROBADO
- When intento registrar su devolución (RN-05c.1)
- Then veo el mensaje "El préstamo no ha sido entregado" y el estado no cambia

**Escenario 5: Devolución con fecha fin pasada**
- Given que hoy es 15 de noviembre y un préstamo ENTREGADO de 2 unidades con fecha fin 13 de noviembre
- When registro la devolución con las 2 unidades BUENO (RN-05c.1, RN-05c.4)
- Then pasa a DEVUELTO y deja de retener unidades

**Escenario 5a: La devolución libera la retención**
- Given que hoy es 15 de noviembre, un equipo de 5 unidades y un préstamo ENTREGADO de 2 unidades con fecha fin 13 de noviembre, sin devolver (disponibilidad del 16 al 18 de noviembre: 3 unidades)
- When registro la devolución con las 2 unidades BUENO (RN-05c.4)
- Then la disponibilidad del 16 al 18 de noviembre pasa a 5 unidades

**Escenario 5b: Devolución de un préstamo VENCIDO (aplica cuando exista SH-02)**
- Given un préstamo VENCIDO de 2 unidades
- When registro la devolución con las 2 unidades BUENO (RN-05c.1, RN-05c.7)
- Then pasa a DEVUELTO y deja de retener unidades

**Escenario 6: Permisos**
- Given que inicié sesión como ESTUDIANTE
- When intento registrar una devolución (RN-05c.6)
- Then veo el mensaje "Acceso denegado"

### HU-05d · Registrar la devolución con daños o pérdidas
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero registrar unidades devueltas dañadas o perdidas para que el inventario refleje solo las unidades realmente utilizables y quede constancia del daño.

**Reglas de negocio**
- RN-05d.1 Aplica cuando al menos una unidad de la devolución queda DAÑADO o PERDIDO; para esas unidades la observación es obligatoria. El préstamo pasa a DEVUELTO con las mismas condiciones de HU-05c (RN-05c.1, RN-05c.2).
- RN-05d.2 Las unidades DAÑADO o PERDIDO se restan de las unidades totales del equipo y no vuelven a la disponibilidad; las BUENO o CON_DESPERFECTOS sí vuelven. El encargado puede reponer unidades editando el equipo.
- RN-05d.3 Si el total del equipo llega a 0, el equipo se muestra como "No disponible" hasta que se reponga; la disponibilidad nunca se muestra negativa (PA-18).
- RN-05d.4 Si tras la resta un préstamo APROBADO futuro queda con más unidades que el total del equipo, el encargado ve un aviso con esos préstamos. El aviso solo informa: un préstamo APROBADO no se rechaza (RN-05a.1). El encargado puede reponer unidades editando el equipo; si no lo hace, la entrega queda sujeta a "Unidades insuficientes" (HU-05b, RN-05b.6) y, si no se recoge dentro del plazo, el préstamo se cierra como "No recogido" (HU-05e) (confirmado, PA-20).
- RN-05d.5 Solo ENCARGADO y ADMIN registran estas devoluciones.

**Criterios de aceptación**
**Escenario 1: Equipo dañado**
- Given un equipo con 5 unidades y un préstamo ENTREGADO de 2 unidades
- When registro la devolución con las 2 unidades DAÑADO y la observación "Pantalla rota" (RN-05d.1, RN-05d.2)
- Then pasa a DEVUELTO y las unidades totales del equipo bajan a 3

**Escenario 2: Devolución mixta**
- Given un equipo con 5 unidades y un préstamo ENTREGADO de 2 unidades
- When registro la devolución con 1 unidad BUENO y 1 unidad DAÑADO con la observación "Teclado roto" (RN-05d.2)
- Then pasa a DEVUELTO, el total baja a 4 y quedan 4 unidades disponibles

**Escenario 3: DAÑADO sin observación**
- Given un préstamo ENTREGADO
- When registro la devolución con una unidad DAÑADO y sin observación (RN-05d.1)
- Then veo el mensaje "La observación es obligatoria" y el estado no cambia

**Escenario 4: El total llega a 0**
- Given un equipo de 2 unidades y un préstamo ENTREGADO de 2 unidades
- When registro la devolución con las 2 unidades PERDIDO y la observación "Extravío" (RN-05d.3)
- Then pasa a DEVUELTO, el total del equipo es 0 y el equipo se muestra como "No disponible"

**Escenario 5: Préstamo aprobado afectado**
- Given un equipo de 2 unidades, un préstamo ENTREGADO de 2 unidades y un préstamo APROBADO futuro de 2 unidades
- When registro la devolución con 1 unidad BUENO y 1 unidad PERDIDO con la observación "Extravío" (RN-05d.4)
- Then pasa a DEVUELTO, el total baja a 1 y veo un aviso informativo que lista el préstamo APROBADO futuro de 2 unidades como afectado, sin opción de rechazarlo

**Escenario 6: Permisos**
- Given que inicié sesión como ESTUDIANTE
- When intento registrar una devolución con unidades dañadas (RN-05d.5)
- Then veo el mensaje "Acceso denegado"

### HU-05e · Cierre automático de préstamos no recogidos
**Prioridad:** Must
**Historia:** Como ENCARGADO quiero que los préstamos aprobados que no se recogen a tiempo se cierren solos para no mantener unidades reservadas para quien no llegó.

**Reglas de negocio**
- RN-05e.1 Un préstamo APROBADO sin entregar pasa automáticamente a RECHAZADO con el motivo "No recogido" cuando vence su plazo de recogida (convenciones). Deja de retener unidades, de bloquear la baja del equipo y de contar en la ocupación. El cierre lo hace el sistema, no el encargado (confirmado, PA-12).
- RN-05e.2 El plazo de recogida son 2 horas de servicio (8:00 AM a 5:00 PM) contadas desde la hora de aprobación, o desde las 8:00 AM del día de inicio si se aprobó antes de ese día. Si las 2 horas no caben en el día, el resto se cuenta desde las 8:00 AM del día siguiente (confirmado, PA-19). Para un préstamo de 1 día aprobado después de las 3:00 PM, el plazo llega hasta las 10:00 AM del día siguiente (confirmado, PA-22; su relación con la regla general, PA-26).
- RN-05e.3 Al cerrarse un préstamo como "No recogido", el sistema envía una notificación dentro de la aplicación a todos los ENCARGADO (sin filtro por área, como RN-SH02.4) y al estudiante titular, con el equipo, las fechas y el motivo "No recogido".
- RN-05e.4 Un préstamo entregado dentro del plazo no se cierra.
- RN-05e.5 El cierre automático no ocurre antes de que termine el plazo, aunque la fecha fin del préstamo ya haya pasado; hasta entonces el préstamo sigue APROBADO y retiene sus unidades según su rango efectivo de retención (convenciones, PA-28).

**Criterios de aceptación**
**Escenario 1: Aprobación anticipada, cierre a las 10:00 AM exactas**
- Given un préstamo del 10 al 12 de noviembre aprobado el 8 de noviembre y sin entregar
- When el reloj marca las 10:00 AM del 10 de noviembre (RN-05e.1, RN-05e.2)
- Then el préstamo pasa a RECHAZADO con el motivo "No recogido" y deja de retener unidades

**Escenario 2: A las 9:59 AM sigue APROBADO**
- Given un préstamo del 10 al 12 de noviembre aprobado el 8 de noviembre y sin entregar
- When el reloj marca las 9:59 AM del 10 de noviembre (RN-05e.2)
- Then sigue APROBADO

**Escenario 3: Aprobación a las 11:00 AM**
- Given un préstamo con inicio el 10 de noviembre aprobado ese día a las 11:00 AM y sin entregar
- When el reloj marca la 1:00 PM (RN-05e.2)
- Then pasa a RECHAZADO con el motivo "No recogido"

**Escenario 4: Aprobación a las 4:00 PM**
- Given un préstamo del 10 al 12 de noviembre aprobado el 10 de noviembre a las 4:00 PM y sin entregar
- When el reloj marca las 9:00 AM del 11 de noviembre (1 hora de servicio hoy y 1 mañana) (RN-05e.2)
- Then pasa a RECHAZADO con el motivo "No recogido"

**Escenario 5: Aprobación a las 5:00 PM**
- Given un préstamo del 10 al 12 de noviembre aprobado el 10 de noviembre a las 5:00 PM y sin entregar
- When el reloj marca las 10:00 AM del 11 de noviembre (RN-05e.2)
- Then pasa a RECHAZADO con el motivo "No recogido"

**Escenario 5b: Préstamo de 1 día aprobado a las 3:00 PM**
- Given un préstamo del 10 al 10 de noviembre aprobado el 10 de noviembre a las 3:00 PM y sin entregar
- When el reloj marca las 5:00 PM del 10 de noviembre (RN-05e.2)
- Then pasa a RECHAZADO con el motivo "No recogido"

**Escenario 5c: Préstamo de 1 día aprobado a las 3:01 PM**
- Given un préstamo del 10 al 10 de noviembre aprobado el 10 de noviembre a las 3:01 PM y sin entregar
- When el reloj marca las 5:00 PM del 10 de noviembre (RN-05e.2)
- Then sigue APROBADO y retiene sus unidades

**Escenario 5d: El cierre llega a las 10:00 AM del día siguiente**
- Given un préstamo del 10 al 10 de noviembre aprobado el 10 de noviembre a las 5:00 PM y sin entregar
- When el reloj marca las 10:00 AM del 11 de noviembre (RN-05e.2, RN-05e.5)
- Then pasa a RECHAZADO con el motivo "No recogido"

**Escenario 5e: Sin cierre a medianoche**
- Given un préstamo del 10 al 10 de noviembre aprobado el 10 de noviembre a las 5:00 PM y sin entregar
- When el sistema realiza la revisión de las 00:05 del 11 de noviembre (RN-05e.5)
- Then sigue APROBADO

**Escenario 6: Notificación al ENCARGADO**
- Given un préstamo APROBADO que se cierra automáticamente como "No recogido"
- When un ENCARGADO abre la aplicación (RN-05e.3)
- Then ve una notificación con el equipo, las fechas y el motivo "No recogido"

**Escenario 7: Notificación al estudiante**
- Given un préstamo APROBADO que se cierra automáticamente como "No recogido"
- When el estudiante titular abre la aplicación (RN-05e.3)
- Then ve una notificación con el equipo, las fechas y el motivo "No recogido"

**Escenario 8: Préstamo ya entregado**
- Given un préstamo entregado a las 9:00 AM del día de inicio
- When el reloj marca las 10:00 AM (RN-05e.4)
- Then sigue ENTREGADO

---

## Should

### SH-02 · Marcado de préstamos vencidos
**Prioridad:** Should
**Historia:** Como ENCARGADO quiero que los préstamos no devueltos a tiempo se marquen como vencidos y generen alertas para reclamar los equipos pendientes y no perderlos de vista.

**Reglas de negocio**
- RN-SH02.1 El sistema revisa automáticamente cada día a las 00:05 y pasa a VENCIDO todo préstamo ENTREGADO cuya fecha fin efectiva (convenciones) sea anterior al día en curso.
- RN-SH02.2 Solo los préstamos ENTREGADO pueden pasar a VENCIDO.
- RN-SH02.3 Un préstamo VENCIDO retiene unidades hasta su devolución (ver HU-03, RN-03.2).
- RN-SH02.4 Cada préstamo VENCIDO genera una alerta visible en la aplicación para todos los ENCARGADO y ADMIN, con equipo, estudiante, cantidad y días de retraso (contados desde la fecha fin efectiva). Sin filtro por área (PA-16).
- RN-SH02.5 La alerta se cierra automáticamente cuando el préstamo pasa a DEVUELTO.

**Criterios de aceptación**
**Escenario 1: Marcado**
- Given que hoy es 20 de noviembre y un préstamo ENTREGADO con fecha fin 19 de noviembre
- When el sistema realiza la revisión diaria (RN-SH02.1)
- Then el préstamo pasa a VENCIDO

**Escenario 2: Fecha fin hoy**
- Given que hoy es 20 de noviembre y un préstamo ENTREGADO con fecha fin 20 de noviembre
- When el sistema realiza la revisión diaria (RN-SH02.1)
- Then sigue ENTREGADO

**Escenario 3: Préstamo no entregado**
- Given un préstamo APROBADO con fecha fin ayer
- When el sistema realiza la revisión diaria (RN-SH02.2)
- Then no pasa a VENCIDO

**Escenario 4: Alerta visible**
- Given un préstamo marcado VENCIDO con 1 día de retraso
- When abro la aplicación como ENCARGADO (RN-SH02.4)
- Then veo una alerta con el equipo, el estudiante, la cantidad y "1 día de retraso"

**Escenario 5: Alerta se cierra**
- Given una alerta de un préstamo VENCIDO
- When registro su devolución (RN-SH02.5)
- Then la alerta deja de mostrarse

### SH-03 · Sanciones por retraso
**Prioridad:** Should
**Historia:** Como ENCARGADO quiero que un estudiante con retraso quede bloqueado temporalmente al solicitar, para proteger la disponibilidad del inventario.

**Dependencia declarada:** RN-SH03.5 y el escenario 6 requieren el estado VENCIDO de SH-02. El resto de esta historia solo necesita HU-04 y HU-05c.

**Reglas de negocio**
- RN-SH03.1 Días de retraso = fecha de devolución - fecha fin efectiva del préstamo (si es mayor que 0). Una devolución con retraso genera un bloqueo de 1 día por cada día de retraso, con máximo de 15 días, contados desde el día siguiente a la devolución.
- RN-SH03.2 Mientras dure el bloqueo no se pueden crear solicitudes; sí se puede consultar disponibilidad e historial.
- RN-SH03.3 El bloqueo se levanta solo al terminar su último día.
- RN-SH03.4 El estudiante ve la fecha en que podrá volver a solicitar.
- RN-SH03.5 Un estudiante con un préstamo en estado VENCIDO sin devolver tampoco puede crear solicitudes.
- RN-SH03.6 Si ya hay un bloqueo vigente y se genera otro, prevalece la fecha de fin más lejana; los bloqueos no se suman.

Nota: esta regla de bloqueo se aplica al crear una solicitud (HU-04) sin cambiar las demás reglas de esa historia.

**Criterios de aceptación**
**Escenario 1: Bloqueo tras devolución con retraso**
- Given un préstamo ENTREGADO cuya fecha fin fue el 18 de noviembre
- When registro su devolución el 20 de noviembre (2 días de retraso) (RN-SH03.1)
- Then el estudiante queda bloqueado el 21 y el 22 de noviembre y puede solicitar desde el 23

**Escenario 2: Tope de 15 días**
- Given un préstamo ENTREGADO con fecha fin 1 de noviembre
- When registro su devolución el 21 de noviembre (20 días de retraso) (RN-SH03.1)
- Then el bloqueo dura 15 días, del 22 de noviembre al 6 de diciembre

**Escenario 3: Solicitud durante el bloqueo**
- Given un estudiante bloqueado el 21 y el 22 de noviembre
- When intenta enviar una solicitud el 21 de noviembre (RN-SH03.2, RN-SH03.4)
- Then se rechaza con el mensaje "Podrás volver a solicitar el 23 de noviembre"

**Escenario 3b: Dos bloqueos solapados**
- Given un estudiante bloqueado del 21 al 25 de noviembre
- When registro el 22 de noviembre la devolución de otro préstamo con 1 día de retraso, que generaría bloqueo hasta el 23 (RN-SH03.6)
- Then el estudiante sigue bloqueado hasta el 25 de noviembre y puede solicitar desde el 26

**Escenario 4: Fin del bloqueo**
- Given un estudiante cuyo bloqueo terminó el 22 de noviembre
- When envía una solicitud válida el 23 de noviembre (RN-SH03.3)
- Then la solicitud se registra en estado SOLICITADO

**Escenario 5: Devolución a tiempo**
- Given un préstamo ENTREGADO con fecha fin 18 de noviembre
- When registro su devolución el 18 de noviembre (RN-SH03.1)
- Then el estudiante no queda bloqueado

**Escenario 6: Préstamo VENCIDO sin devolver**
- Given un estudiante con un préstamo VENCIDO sin devolver
- When intenta enviar una solicitud (RN-SH03.5)
- Then se rechaza con el mensaje "Tienes un préstamo vencido pendiente de devolución"

**Escenario 7: Entrega tardía dentro del plazo, devuelto el mismo día**
- Given un préstamo del 10 al 10 de noviembre aprobado a las 5:00 PM del 10 y entregado el 11 de noviembre a las 8:30 AM (fecha fin efectiva: 11 de noviembre)
- When registro su devolución el 11 de noviembre (RN-SH03.1)
- Then el estudiante no queda bloqueado

### SH-06 · Alerta de préstamo próximo a vencer
**Prioridad:** Should
**Historia:** Como ESTUDIANTE quiero recibir una alerta el día antes de la fecha fin de mi préstamo para devolver el equipo a tiempo y evitar el bloqueo por retraso.

**Dependencia declarada:** el beneficio de evitar el bloqueo presupone SH-03; la alerta funciona sin SH-03. El cierre al pasar a VENCIDO aplica cuando exista SH-02.

**Reglas de negocio**
- RN-SH06.1 En la revisión diaria de las 00:05, el sistema genera una alerta de "próximo a vencer" para el estudiante titular de cada préstamo ENTREGADO cuya fecha fin efectiva es mañana (antelación de 1 día).
- RN-SH06.2 Si un préstamo se entrega cuando su fecha fin efectiva ya es mañana (préstamos de 2 días entregados el día de inicio), la alerta se genera en el momento de la entrega (confirmado, PA-21).
- RN-SH06.3 Si la fecha fin efectiva es hoy no se genera alerta (ya no queda un día de antelación).
- RN-SH06.4 La alerta solo la ve el estudiante titular, con equipo, cantidad y fecha fin (fecha fin efectiva). No se genera para préstamos APROBADO ni para los ya devueltos.
- RN-SH06.5 La alerta se cierra al devolverse el préstamo o al pasar a VENCIDO.

**Criterios de aceptación**
**Escenario 1: Alerta por la revisión diaria**
- Given que hoy es 20 de noviembre y un préstamo ENTREGADO mío con fecha fin 21 de noviembre
- When el sistema realiza la revisión diaria (RN-SH06.1)
- Then al abrir la aplicación veo una alerta con el equipo, la cantidad y "Vence el 21 de noviembre"

**Escenario 2: Sin alerta con más antelación**
- Given que hoy es 20 de noviembre y un préstamo ENTREGADO mío con fecha fin 22 de noviembre
- When el sistema realiza la revisión diaria (RN-SH06.1)
- Then no se genera ninguna alerta de próximo a vencer

**Escenario 3: La alerta es solo del titular**
- Given un préstamo ENTREGADO de otro estudiante con fecha fin mañana
- When abro la aplicación como ESTUDIANTE (RN-SH06.4)
- Then no veo ninguna alerta de ese préstamo

**Escenario 4: Alerta se cierra al devolver**
- Given una alerta de próximo a vencer de un préstamo mío
- When el encargado registra su devolución (RN-SH06.5)
- Then la alerta deja de mostrarse

**Escenario 5: Préstamo de 2 días entregado el primer día**
- Given un préstamo del 20 al 21 de noviembre y que hoy es 20 de noviembre
- When el encargado registra la entrega a las 8:30 AM (RN-SH06.2)
- Then al abrir la aplicación veo una alerta "Vence el 21 de noviembre"

**Escenario 6: Préstamo de 1 día**
- Given un préstamo del 20 al 20 de noviembre y que hoy es 20 de noviembre
- When el encargado registra la entrega a las 8:30 AM (RN-SH06.3)
- Then no se genera alerta de próximo a vencer

### SH-07 · Cancelar mi solicitud
**Prioridad:** Should
**Historia:** Como ESTUDIANTE quiero cancelar mi solicitud o mi préstamo aprobado antes de la entrega para liberar las unidades reservadas cuando ya no los necesito.

**Reglas de negocio**
- RN-SH07.1 Solo el estudiante titular cancela su solicitud (PA-11). El sistema nunca cancela por su cuenta: el estado CANCELADO solo lo produce el estudiante.
- RN-SH07.2 Solo se cancela mientras la solicitud todavía pueda resolverse: una SOLICITADO hasta el día de inicio (incluido) y un APROBADO hasta que venza su plazo de recogida. Pasado ese momento ya no se cancela porque el sistema las cierra solas: la SOLICITADO como "Sin resolver a tiempo" (RN-05a.11) y el APROBADO como "No recogido" (RN-05e.1). En todo caso es antes de la entrega (confirmado, PA-11 y PA-24). Entre las 00:00 y las 00:05 del día siguiente al de inicio una SOLICITADO ya no se puede cancelar, aunque el sistema aún no la haya cerrado.
- RN-SH07.3 Un préstamo ENTREGADO, VENCIDO, DEVUELTO, RECHAZADO o CANCELADO no se cancela.
- RN-SH07.4 Al cancelar, el préstamo pasa a CANCELADO, deja de retener unidades, de bloquear la baja del equipo y de contar en el límite de 3 de HU-04 (confirmado, PA-24).
- RN-SH07.5 El motivo de cancelación es opcional (máximo 250 caracteres). Si viene vacío, el motivo queda registrado como "Cancelado por usuario".
- RN-SH07.6 Las solicitudes se cancelan completas; no hay aprobaciones ni cancelaciones parciales de equipos (PA-11).

**Criterios de aceptación**
**Escenario 1: Cancelar una solicitud pendiente**
- Given una solicitud mía en SOLICITADO
- When la cancelo sin escribir motivo (RN-SH07.2, RN-SH07.5)
- Then pasa a CANCELADO con el motivo "Cancelado por usuario" y deja de aparecer entre las solicitudes por resolver del encargado

**Escenario 1b: Cancelar con motivo propio**
- Given una solicitud mía en SOLICITADO
- When la cancelo con el motivo "Cambió la fecha de la práctica" (RN-SH07.5)
- Then pasa a CANCELADO con ese motivo

**Escenario 2: Cancelar un aprobado libera unidades**
- Given un equipo de 5 unidades y un préstamo mío APROBADO de 2 unidades del 10 al 12 de noviembre (3 disponibles)
- When lo cancelo con el motivo "Ya no lo necesito" (RN-SH07.4)
- Then pasa a CANCELADO y la disponibilidad del 10 al 12 de noviembre vuelve a 5 unidades

**Escenario 2b: Solicitud el día de inicio**
- Given que hoy es 10 de noviembre y una solicitud mía en SOLICITADO con inicio el 10 de noviembre
- When la cancelo (RN-SH07.2)
- Then pasa a CANCELADO

**Escenario 2c: Solicitud tras su día de inicio**
- Given que hoy es 11 de noviembre y una solicitud mía con inicio el 10 de noviembre que se cerró sola como RECHAZADO "Sin resolver a tiempo"
- When intento cancelarla (RN-SH07.2)
- Then veo el mensaje "El préstamo ya no se puede cancelar" y el estado no cambia

**Escenario 2c2: Entre las 00:00 y las 00:05 del día siguiente al de inicio**
- Given que son las 00:03 del 11 de noviembre y una solicitud mía en SOLICITADO con inicio el 10 de noviembre, aún sin cerrar por el sistema
- When intento cancelarla (RN-SH07.2)
- Then veo el mensaje "El préstamo ya no se puede cancelar" y el estado no cambia

**Escenario 2d: Aprobado con plazo de recogida vencido**
- Given un préstamo mío que se cerró solo como RECHAZADO "No recogido"
- When intento cancelarlo (RN-SH07.2)
- Then veo el mensaje "El préstamo ya no se puede cancelar" y el estado no cambia

**Escenario 3: Préstamo ya entregado**
- Given un préstamo mío en estado ENTREGADO
- When intento cancelarlo (RN-SH07.3)
- Then veo el mensaje "El préstamo ya fue entregado" y el estado no cambia

**Escenario 4: Préstamo vencido o devuelto**
- Given un préstamo mío en estado DEVUELTO
- When intento cancelarlo (RN-SH07.3)
- Then veo el mensaje "El préstamo ya no se puede cancelar" y el estado no cambia

**Escenario 4b: Solicitud ya rechazada o cancelada**
- Given una solicitud mía en RECHAZADO y otra en CANCELADO
- When intento cancelar cada una (RN-SH07.3)
- Then veo el mensaje "El préstamo ya no se puede cancelar" y el estado no cambia

**Escenario 5: Solicitud ajena**
- Given una solicitud SOLICITADO de otro estudiante
- When intento cancelarla (RN-SH07.1)
- Then veo el mensaje "Acceso denegado"

### SH-01 · Historial "Mis préstamos"
**Prioridad:** Should
**Historia:** Como ESTUDIANTE quiero ver mis préstamos filtrados por estado y fechas para saber qué debo devolver y qué ocurrió con mis solicitudes.

**Reglas de negocio**
- RN-SH01.1 El estudiante solo ve sus propios préstamos.
- RN-SH01.2 Se filtra por estado (SOLICITADO, APROBADO, RECHAZADO, CANCELADO, ENTREGADO, DEVUELTO, VENCIDO) y por rango de fechas; ambos filtros son opcionales y combinables.
- RN-SH01.3 El filtro de fechas compara contra la fecha de inicio del préstamo: se muestran los préstamos cuya fecha de inicio está dentro del rango, extremos incluidos.
- RN-SH01.4 Los filtros se aplican sobre las solicitudes que el estudiante ya ve en HU-04 (estado y motivo de rechazo se muestran allí; no se repiten aquí).

**Criterios de aceptación**
**Escenario 1: Filtrar por estado**
- Given 2 préstamos míos ENTREGADO y 3 DEVUELTO
- When filtro por ENTREGADO (RN-SH01.2)
- Then veo solo los 2 ENTREGADO

**Escenario 2: Filtrar por fecha de inicio**
- Given un préstamo mío del 5 al 7 de noviembre y otro del 20 al 22 de noviembre
- When filtro del 1 al 10 de noviembre (RN-SH01.3)
- Then veo solo el préstamo del 5 al 7 de noviembre

**Escenario 3: Aislamiento**
- Given que existen préstamos de otro estudiante
- When abro mi historial (RN-SH01.1)
- Then no veo ningún préstamo ajeno

**Escenario 4: Sin resultados**
- Given que no tengo préstamos VENCIDO
- When filtro por VENCIDO (RN-SH01.2)
- Then veo "No tienes préstamos con ese filtro"

**Escenario 5: Combinar estado y fechas**
- Given 1 préstamo mío DEVUELTO con inicio el 5 de noviembre y otro DEVUELTO con inicio el 20 de noviembre
- When filtro por DEVUELTO y del 1 al 10 de noviembre (RN-SH01.2)
- Then veo solo el préstamo con inicio el 5 de noviembre

### SH-04 · Panel de métricas
**Prioridad:** Should
**Historia:** Como ADMIN quiero ver los equipos más prestados, los vencidos y la ocupación del inventario para decidir compras y detectar problemas de devolución.

**Reglas de negocio**
- RN-SH04.1 El ranking y el conteo de vencidos se calculan sobre los préstamos cuya fecha de inicio está dentro del rango elegido, extremos incluidos. La ocupación sigue su propia regla (RN-SH04.4).
- RN-SH04.2 Ranking: los 10 equipos con más préstamos que llegaron a entregarse (estados ENTREGADO, VENCIDO o DEVUELTO), de mayor a menor número de préstamos.
- RN-SH04.3 Vencidos: número de préstamos en estado VENCIDO dentro del rango.
- RN-SH04.4 Ocupación = unidades-día de cada préstamo APROBADO, ENTREGADO, VENCIDO o DEVUELTO que caen dentro del rango, contando los días de su rango efectivo de retención (convenciones; cuente cuando cuente su fecha de inicio, incluso si empezó antes del rango). Un ENTREGADO o VENCIDO cuenta hasta su devolución y, si aún no se devolvió, hasta hoy (PA-28). El total se divide entre (unidades totales de equipos activos, es decir no dados de baja, x días del rango), en porcentaje.
- RN-SH04.5 Solo ADMIN accede al panel.

**Criterios de aceptación**
**Escenario 1: Ranking**
- Given en el rango del 1 al 30 de noviembre, el equipo A con 3 préstamos entregados y el equipo B con 1
- When abro el panel con ese rango (RN-SH04.1, RN-SH04.2)
- Then veo A en primer lugar con 3 préstamos y B en segundo con 1

**Escenario 2: Vencidos**
- Given en el rango del 1 al 30 de noviembre, 2 préstamos VENCIDO y 5 DEVUELTO
- When abro el panel con ese rango (RN-SH04.3)
- Then veo 2 préstamos vencidos

**Escenario 3: Ocupación**
- Given el rango del 1 al 7 de noviembre (7 días), 5 unidades totales en el inventario activo y un préstamo ENTREGADO de 1 unidad durante los 7 días
- When abro el panel con ese rango (RN-SH04.4)
- Then veo una ocupación de 20% (7 de 35 unidades-día)

**Escenario 3b: Préstamo que empieza antes del rango**
- Given el rango del 1 al 10 de noviembre (10 días), 5 unidades totales y un préstamo de 1 unidad del 29 de octubre al 5 de noviembre, devuelto el 5 de noviembre
- When abro el panel con ese rango (RN-SH04.4)
- Then veo una ocupación de 10% (5 de 50 unidades-día, contando solo del 1 al 5 de noviembre)

**Escenario 3c: ENTREGADO sin devolver cuenta hasta hoy**
- Given que hoy es 7 de noviembre, el rango del 1 al 10 de noviembre (10 días), 5 unidades totales y un préstamo ENTREGADO de 1 unidad del 30 de octubre al 5 de noviembre (fecha fin efectiva 5 de noviembre), sin devolver
- When abro el panel con ese rango (RN-SH04.4)
- Then veo una ocupación de 14% (7 de 50 unidades-día, contando del 1 al 7 de noviembre)

**Escenario 4: Sin datos**
- Given un rango sin préstamos
- When abro el panel (RN-SH04.1)
- Then veo ranking vacío, 0 vencidos, 0% de ocupación y el mensaje "Sin datos en el periodo"

**Escenario 5: Permisos**
- Given que soy ENCARGADO
- When intento abrir el panel (RN-SH04.5)
- Then veo el mensaje "Acceso denegado"

### SH-05 · Exportación a CSV
**Prioridad:** Should
**Historia:** Como ENCARGADO quiero descargar el inventario y los préstamos en CSV para elaborar reportes e inventarios físicos.

**Reglas de negocio**
- RN-SH05.1 El CSV de inventario tiene las columnas: código de inventario, nombre, categoría, unidades totales y estado. Excluye equipos dados de baja.
- RN-SH05.2 El CSV de préstamos tiene las columnas: identificador, correo del estudiante, equipos y cantidades, fecha inicio, fecha fin, estado, fecha de entrega y fecha de devolución.
- RN-SH05.3 Los filtros de préstamos (rango de fechas y estado) son opcionales y combinables; el rango compara contra la fecha de inicio, extremos incluidos. Sin filtros se exportan todos.
- RN-SH05.4 Si no hay resultados, el archivo se genera solo con la fila de columnas.
- RN-SH05.5 Solo ENCARGADO y ADMIN exportan.

**Criterios de aceptación**
**Escenario 1: Exportar inventario**
- Given 12 equipos activos y 2 dados de baja
- When exporto el inventario (RN-SH05.1)
- Then el archivo contiene la fila de columnas y 12 filas de equipos

**Escenario 2: Préstamos con filtros**
- Given préstamos de varios estados
- When exporto solo los DEVUELTO con fecha de inicio del 1 al 30 de noviembre (RN-SH05.3)
- Then el archivo contiene únicamente esos préstamos

**Escenario 3: Préstamos sin filtros**
- Given 20 préstamos de distintos estados
- When exporto sin filtros (RN-SH05.3)
- Then el archivo contiene los 20 préstamos con las columnas definidas (RN-SH05.2)

**Escenario 4: Sin resultados**
- Given que no hay préstamos RECHAZADO
- When exporto solo los RECHAZADO (RN-SH05.4)
- Then el archivo contiene únicamente la fila de columnas

**Escenario 5: Permisos**
- Given que soy ESTUDIANTE
- When intento exportar (RN-SH05.5)
- Then veo el mensaje "Acceso denegado"

### SH-11 · Bloqueo temporal por intentos fallidos
**Prioridad:** Should
**Historia:** Como ESTUDIANTE, ENCARGADO o ADMIN quiero que mi cuenta se bloquee un tiempo tras varios intentos fallidos de ingreso para que nadie pueda adivinar mi contraseña y usar mi cuenta.

**Dependencia declarada:** esta historia usa el mismo mensaje "Credenciales inválidas" de HU-01b (RN-01b.2) para todos los casos de fallo y bloqueo; no lo sustituye por otro.

**Reglas de negocio**
- RN-SH11.1 Tras 3 intentos fallidos consecutivos de inicio de sesión con el mismo correo, el acceso se bloquea 15 minutos. "Consecutivos" significa 3 intentos fallidos sin ningún inicio de sesión exitoso entre medias, sin ventana de tiempo; el contador se reinicia con un inicio de sesión exitoso o al terminar el bloqueo (confirmado, PA-32).
- RN-SH11.2 El mensaje no revela si la cuenta existe, si está dada de baja, si está bloqueada ni qué dato es incorrecto: es siempre "Credenciales inválidas" para credenciales incorrectas, correo inexistente, cuenta dada de baja y cuenta bloqueada.
- RN-SH11.3 Durante el bloqueo, ni siquiera la contraseña correcta permite el acceso.
- RN-SH11.4 Un inicio de sesión correcto antes del tercer fallo reinicia la cuenta de intentos.
- RN-SH11.5 Al cumplirse los 15 minutos el bloqueo se levanta solo y la cuenta de intentos vuelve a 0.
- RN-SH11.6 Un correo que no existe cuenta intentos y se bloquea igual, para no distinguirlo de uno existente.
- RN-SH11.7 En una cuenta dada de baja (SH-08), todo intento de inicio de sesión, con la contraseña correcta o no, recibe "Credenciales inválidas" y no da acceso.
- RN-SH11.8 Además del bloqueo por cuenta, hay un límite por origen de conexión: tras 10 intentos fallidos desde el mismo origen, los intentos siguientes de ese origen reciben "Demasiados intentos. Inténtalo de nuevo más tarde". Los 15 minutos son una ventana que empieza en el primer intento fallido de la serie; al décimo fallo el origen queda bloqueado hasta que se cumplan 15 minutos desde ese primer fallo. (confirmado, PA-35). Este mensaje no depende del correo ni de si los datos son correctos (confirmado, PA-32).

**Criterios de aceptación**
**Escenario 1: Tercer intento fallido bloquea**
- Given una cuenta con 2 intentos fallidos consecutivos
- When intento iniciar sesión con una contraseña equivocada por tercera vez (RN-SH11.1)
- Then veo "Credenciales inválidas" y el acceso queda bloqueado 15 minutos

**Escenario 2: Contraseña correcta durante el bloqueo**
- Given una cuenta bloqueada hace 5 minutos
- When inicio sesión con la contraseña correcta (RN-SH11.3)
- Then no accedo y veo exactamente "Credenciales inválidas"

**Escenario 3: Fin del bloqueo**
- Given una cuenta bloqueada hace 15 minutos
- When inicio sesión con la contraseña correcta (RN-SH11.5)
- Then accedo con normalidad

**Escenario 4: Un acierto reinicia los intentos**
- Given una cuenta con 2 intentos fallidos consecutivos
- When inicio sesión correctamente (RN-SH11.4)
- Then accedo y la cuenta de intentos fallidos vuelve a 0

**Escenario 5: Correo que no existe**
- Given un correo "nadie@institucion.edu" sin cuenta
- When intento iniciar sesión con él por tercera vez seguida (RN-SH11.2, RN-SH11.6)
- Then veo exactamente el mismo mensaje que para una cuenta existente

**Escenario 6: Cuenta dada de baja con la contraseña correcta**
- Given una cuenta dada de baja
- When intento iniciar sesión con su contraseña correcta (RN-SH11.7)
- Then no accedo y veo "Credenciales inválidas", igual que con una contraseña equivocada

**Escenario 7: Límite por origen de conexión**
- Given 10 intentos fallidos desde el mismo origen, con correos distintos, el primero hace 10 minutos
- When ese origen intenta iniciar sesión con cualquier correo y la contraseña correcta (RN-SH11.8)
- Then veo "Demasiados intentos. Inténtalo de nuevo más tarde" sin indicar si el correo existe

**Escenario 8: Fin de la ventana del origen**
- Given un origen cuyo primer intento fallido de una serie de 10 ocurrió hace 15 minutos
- When intenta iniciar sesión con credenciales correctas (RN-SH11.8)
- Then accede con normalidad

### SH-09 · Duración y expiración de la sesión
**Prioridad:** Should
**Historia:** Como ESTUDIANTE, ENCARGADO o ADMIN quiero que mi sesión se cierre sola tras un tiempo para que nadie use mi cuenta en un equipo compartido del laboratorio o de la biblioteca.

**Reglas de negocio**
- RN-SH09.1 La sesión dura como máximo 1 hora para un ESTUDIANTE y 8 horas para un ENCARGADO, contadas desde el inicio de sesión. Para un ADMIN la duración máxima es de 8 horas (confirmado, PA-30).
- RN-SH09.2 La sesión se mantiene mientras haya actividad: si pasan 30 minutos seguidos sin actividad, expira aunque no se haya alcanzado la duración máxima.
- RN-SH09.3 Al expirar, por inactividad o por duración máxima, se muestra "Tu sesión expiró. Inicia sesión de nuevo" y se pide iniciar sesión.
- RN-SH09.4 Si la cuenta fue dada de baja con una sesión abierta (aplica cuando exista SH-08), el acceso se corta de inmediato para todos los roles y para todas las acciones, sean consultas o acciones que modifican datos: cualquier petición posterior se rechaza con "Tu sesión ya no es válida. Inicia sesión de nuevo" (confirmado, PA-33). No hay ningún margen de tiempo. Al volver a iniciar sesión, la persona recibe "Credenciales inválidas" como cualquier otro caso (RN-01b.2); este texto nunca aparece en el inicio de sesión.
- RN-SH09.5 El usuario puede cerrar su sesión cuando quiera.

**Criterios de aceptación**
**Escenario 1: Estudiante activo llega a 1 hora**
- Given un ESTUDIANTE que inició sesión a las 9:00 AM y actuó cada 20 minutos
- When intenta una acción a las 10:01 AM (RN-SH09.1, RN-SH09.3)
- Then veo "Tu sesión expiró. Inicia sesión de nuevo"

**Escenario 2: Inactividad de 30 minutos**
- Given un ENCARGADO que inició sesión a las 9:00 AM y su última actividad fue a las 9:10 AM
- When intenta una acción a las 9:41 AM (RN-SH09.2)
- Then veo "Tu sesión expiró. Inicia sesión de nuevo"

**Escenario 3: La actividad mantiene la sesión**
- Given un ENCARGADO que inició sesión a las 9:00 AM y actuó a las 9:20 AM
- When intenta una acción a las 9:45 AM (RN-SH09.2)
- Then la acción se ejecuta y la sesión sigue activa

**Escenario 4: Encargado llega a 8 horas**
- Given un ENCARGADO que inició sesión a las 8:00 AM y actuó sin pausas de más de 30 minutos
- When intenta una acción a las 4:01 PM (RN-SH09.1)
- Then veo "Tu sesión expiró. Inicia sesión de nuevo"

**Escenario 5: Cuenta dada de baja, acción que modifica datos**
- Given un ESTUDIANTE con la sesión abierta cuya cuenta acaba de darse de baja
- When intenta enviar una solicitud de préstamo (RN-SH09.4)
- Then veo "Tu sesión ya no es válida. Inicia sesión de nuevo", la solicitud no se crea y la sesión se cierra

**Escenario 5b: Cuenta de ESTUDIANTE dada de baja, consulta**
- Given un ESTUDIANTE con la sesión abierta cuya cuenta acaba de darse de baja
- When consulta la disponibilidad (RN-SH09.4)
- Then veo "Tu sesión ya no es válida. Inicia sesión de nuevo", no se muestran datos y la sesión se cierra

**Escenario 5b2: Cuenta de ENCARGADO dada de baja, consulta**
- Given un ENCARGADO con la sesión abierta cuya cuenta acaba de darse de baja
- When consulta la lista de solicitudes pendientes (RN-SH09.4)
- Then veo "Tu sesión ya no es válida. Inicia sesión de nuevo", no se muestran datos y la sesión se cierra

**Escenario 5c: Sesión de ADMIN de 8 horas**
- Given un ADMIN que inició sesión a las 8:00 AM y actuó sin pausas de más de 30 minutos
- When intenta una acción a las 4:01 PM (RN-SH09.1)
- Then veo "Tu sesión expiró. Inicia sesión de nuevo"

**Escenario 6: Cerrar sesión**
- Given un usuario con sesión abierta
- When cierra su sesión (RN-SH09.5)
- Then debe iniciar sesión de nuevo para continuar

### SH-08 · Baja de cuentas
**Prioridad:** Should
**Historia:** Como ADMIN quiero dar de baja la cuenta de una persona que ya no pertenece a la institución para que pierda el acceso sin perder el historial de préstamos.

**Dependencia declarada:** SH-08 depende de SH-09 para el corte de las sesiones que la cuenta tenga abiertas. Ya no depende de SH-07: la baja nunca cancela préstamos.

**Reglas de negocio**
- RN-SH08.1 Solo el ADMIN da de baja cuentas (ESTUDIANTE, ENCARGADO u otro ADMIN). Un ADMIN no puede darse de baja a sí mismo ("No puedes darte de baja a ti mismo") ni dar de baja al último ADMIN activo ("Debe existir al menos un administrador activo"). Si se cumplen ambas condiciones a la vez (el único ADMIN intenta darse de baja), se muestra "Debe existir al menos un administrador activo". No existe cambio de roles (PA-2).
- RN-SH08.2 La persona dada de baja no puede iniciar sesión y el mensaje es siempre "Credenciales inválidas", igual que para una cuenta inexistente o una contraseña equivocada (RN-01b.2); nunca se le dice que su cuenta está dada de baja. Si tenía una sesión abierta, se corta de inmediato para todas sus acciones, según SH-09 (RN-SH09.4).
- RN-SH08.3 No se da de baja una cuenta cuyo titular tiene préstamos en curso de cualquier tipo (SOLICITADO, APROBADO, ENTREGADO o VENCIDO); se bloquea con "La cuenta tiene préstamos en curso" (confirmado, PA-36). Se puede dar de baja cuando todos sus préstamos estén en DEVUELTO, RECHAZADO o CANCELADO (confirmado, PA-29).
- RN-SH08.4 La baja no cancela, rechaza ni modifica ningún préstamo y no cambia las unidades retenidas: como solo se da de baja una cuenta sin préstamos en curso, no hay nada que liberar. El estado CANCELADO solo lo produce el estudiante (SH-07).
- RN-SH08.5 Nada se borra: el historial de préstamos, devoluciones y observaciones se conserva y sigue visible para el encargado y en las exportaciones. El correo de una cuenta dada de baja no puede volver a registrarse (RN-01a.2).
- RN-SH08.6 Los préstamos que entregó o devolvió un ENCARGADO dado de baja conservan su nombre como responsable. Las alertas y notificaciones de los encargados dejan de dirigirse a él.
- RN-SH08.7 El ADMIN puede buscar cuentas por correo, por nombre o por rol, y listarlas con su estado (activa o dada de baja), para elegir la que va a dar de baja. Si busca un correo que no existe, ve "Usuario no encontrado"; este mensaje solo lo ve un ADMIN autenticado.

**Criterios de aceptación**
**Escenario 1: Baja de un estudiante sin préstamos en curso**
- Given que soy ADMIN y un estudiante cuyos préstamos están todos en DEVUELTO, RECHAZADO o CANCELADO
- When doy de baja su cuenta (RN-SH08.1)
- Then su titular ya no puede iniciar sesión y, con cualquier contraseña, ve "Credenciales inválidas"

**Escenario 2: Estudiante con préstamo ENTREGADO**
- Given un estudiante con un préstamo ENTREGADO sin devolver
- When intento dar de baja su cuenta (RN-SH08.3)
- Then se bloquea con "La cuenta tiene préstamos en curso" y la cuenta sigue activa

**Escenario 2b: Estudiante con préstamo VENCIDO**
- Given un estudiante con un préstamo VENCIDO sin devolver
- When intento dar de baja su cuenta (RN-SH08.3)
- Then se bloquea con "La cuenta tiene préstamos en curso" y la cuenta sigue activa

**Escenario 3: Estudiante con solicitud o aprobado pendiente**
- Given un estudiante con una solicitud SOLICITADO y un préstamo APROBADO de 2 unidades
- When intento dar de baja su cuenta (RN-SH08.3, RN-SH08.4)
- Then se bloquea con "La cuenta tiene préstamos en curso", ambos préstamos conservan su estado y las 2 unidades siguen retenidas

**Escenario 4: Intento de ingreso de una cuenta dada de baja**
- Given una cuenta dada de baja
- When su titular intenta iniciar sesión con la contraseña correcta (RN-SH08.2)
- Then no accede y ve "Credenciales inválidas", el mismo mensaje que para una cuenta inexistente

**Escenario 4b: Baja de un ENCARGADO**
- Given que soy ADMIN y un ENCARGADO activo
- When doy de baja su cuenta (RN-SH08.1)
- Then el ENCARGADO ya no puede iniciar sesión y sus entregas anteriores conservan su nombre (RN-SH08.6)

**Escenario 5: El historial se conserva**
- Given un estudiante dado de baja con 3 préstamos DEVUELTO
- When el encargado consulta los préstamos DEVUELTO (RN-SH08.5)
- Then ve los 3 préstamos con el nombre del estudiante

**Escenario 6: Último administrador**
- Given que soy el único ADMIN activo
- When intento dar de baja mi propia cuenta (RN-SH08.1)
- Then se bloquea con "Debe existir al menos un administrador activo"

**Escenario 6b: Darse de baja a sí mismo con otro ADMIN activo**
- Given que soy ADMIN y existe otro ADMIN activo
- When intento dar de baja mi propia cuenta (RN-SH08.1)
- Then se bloquea con "No puedes darte de baja a ti mismo"

**Escenario 6c: Baja de otro ADMIN**
- Given que soy ADMIN y existe otro ADMIN activo
- When doy de baja la cuenta del otro ADMIN (RN-SH08.1)
- Then la cuenta queda dada de baja y yo sigo siendo ADMIN activo

**Escenario 6d: Buscar una cuenta**
- Given cuentas de estudiantes y encargados registradas
- When busco por el correo "ana@institucion.edu" (RN-SH08.7)
- Then veo esa cuenta con su rol y su estado

**Escenario 6e: Cuenta que no existe**
- Given que soy ADMIN
- When busco el correo "nadie@institucion.edu" (RN-SH08.7)
- Then veo "Usuario no encontrado"

**Escenario 7: Permisos**
- Given que inicié sesión como ENCARGADO
- When intento dar de baja una cuenta (RN-SH08.1)
- Then veo el mensaje "Acceso denegado"

### SH-10 · Sesión única por usuario
**Prioridad:** Should
**Historia:** Como ESTUDIANTE, ENCARGADO o ADMIN quiero tener una sola sesión abierta y poder cerrar la otra al iniciar sesión para saber que nadie más está usando mi cuenta a la vez.

**Reglas de negocio**
- RN-SH10.1 Un usuario tiene como máximo una sesión activa.
- RN-SH10.2 Si inicia sesión teniendo otra sesión activa en otro lugar, se le informa "Ya tienes una sesión activa en otro lugar" y puede elegir entre cerrar la otra sesión e ingresar, o cancelar el ingreso. Cerrar la otra sesión cubre el cierre de las demás sesiones de la cuenta. Este aviso solo aparece después de autenticarse con credenciales correctas, por lo que no revela nada a quien no las conoce (confirmado, PA-31).
- RN-SH10.3 El corte de la sesión desplazada es inmediato para todas las acciones, consultas incluidas. La sesión desplazada de esta forma muestra, al usarse, "Tu sesión fue cerrada porque iniciaste sesión en otro lugar" (confirmado, PA-33).

**Criterios de aceptación**
**Escenario 1: Aviso de sesión activa**
- Given un usuario con una sesión activa en otro lugar
- When inicia sesión con sus credenciales correctas (RN-SH10.2)
- Then ve "Ya tienes una sesión activa en otro lugar" con las opciones de cerrar la otra o cancelar

**Escenario 2: Cerrar la otra sesión e ingresar**
- Given el aviso de sesión activa en otro lugar
- When elige cerrar la otra sesión (RN-SH10.2, RN-SH10.3)
- Then ingresa y la otra sesión, al usarse, muestra "Tu sesión fue cerrada porque iniciaste sesión en otro lugar"

**Escenario 3: Cancelar el ingreso**
- Given el aviso de sesión activa en otro lugar
- When elige cancelar (RN-SH10.2)
- Then no ingresa y la otra sesión sigue activa

**Escenario 4: Sin otra sesión activa**
- Given un usuario sin ninguna otra sesión activa
- When inicia sesión con sus credenciales correctas (RN-SH10.1)
- Then ingresa directamente, sin aviso

### SH-12 · Cierre de la sesión de otra cuenta por el ADMIN
**Prioridad:** Should
**Historia:** Como ADMIN quiero cerrar la sesión abierta de otra cuenta para proteger los datos cuando una persona pierde un dispositivo o deja su sesión abierta en un equipo ajeno.

**Reglas de negocio**
- RN-SH12.1 Solo el ADMIN cierra la sesión de otra cuenta (de cualquier rol).
- RN-SH12.2 El ADMIN identifica la cuenta por su correo. Si no existe, ve "Usuario no encontrado" (solo lo ve un ADMIN autenticado).
- RN-SH12.3 El ADMIN cierra todas las sesiones activas de la cuenta y el corte es inmediato para todas las acciones, consultas incluidas, sin ningún margen de tiempo: la persona ve al usar cualquiera de sus dispositivos "Tu sesión ya no es válida. Inicia sesión de nuevo" (confirmado, PA-33).
- RN-SH12.4 Si la cuenta no tiene sesión activa, el ADMIN ve "La cuenta no tiene sesión activa".
- RN-SH12.5 Cerrar una sesión no da de baja la cuenta ni borra datos: la persona puede volver a iniciar sesión con sus credenciales.

**Criterios de aceptación**
**Escenario 1: Cerrar la sesión de un estudiante**
- Given que soy ADMIN y el estudiante "ana@institucion.edu" tiene una sesión activa
- When cierro su sesión (RN-SH12.1)
- Then la sesión de Ana, al usarse, muestra "Tu sesión ya no es válida. Inicia sesión de nuevo"

**Escenario 1b: Consulta inmediata tras el cierre**
- Given una sesión de "ana@institucion.edu" que acaba de cerrar un ADMIN
- When Ana consulta la disponibilidad desde su dispositivo (RN-SH12.3)
- Then ve "Tu sesión ya no es válida. Inicia sesión de nuevo" y no se muestran datos

**Escenario 2: La cuenta puede volver a ingresar**
- Given una sesión de "ana@institucion.edu" cerrada por un ADMIN
- When Ana inicia sesión con sus credenciales correctas (RN-SH12.5)
- Then accede con normalidad

**Escenario 3: Cuenta sin sesión activa**
- Given que soy ADMIN y una cuenta sin sesión activa
- When intento cerrar su sesión (RN-SH12.4)
- Then veo "La cuenta no tiene sesión activa"

**Escenario 4: Correo que no existe**
- Given que soy ADMIN
- When intento cerrar la sesión de "nadie@institucion.edu" (RN-SH12.2)
- Then veo "Usuario no encontrado"

**Escenario 5: Permisos**
- Given que inicié sesión como ENCARGADO
- When intento cerrar la sesión de otra cuenta (RN-SH12.1)
- Then veo el mensaje "Acceso denegado"

---

## Preguntas abiertas

Estado: PA-1 a PA-36 están **confirmadas** por el usuario (se listan por trazabilidad). No queda ninguna PA pendiente ni abierta.

- **PA-1** Dominio de correo institucional. Propuesta: "@institucion.edu" (HU-01a).
- **PA-2** Alta de ENCARGADO y ADMIN. Propuesta: carga inicial por la institución con al menos un ADMIN; sin autoservicio ni pantalla de gestión de roles (HU-01a, HU-01b).
- **PA-3** Política de contraseña. Propuesta: mínimo 8 caracteres, una letra y un número.
- **PA-4** Antelación mínima para solicitar. Propuesta: 0 días (se puede iniciar hoy).
- **PA-5** Longitud del motivo de rechazo. Propuesta: 10 a 250 caracteres.
- **PA-6** Estados al devolver y su efecto. Propuesta: BUENO, CON_DESPERFECTOS, DAÑADO, PERDIDO; los dos últimos restan unidades totales.
- **PA-7** Hora de la revisión de vencidos. Propuesta: diaria a las 00:05; vence si la fecha fin es anterior a hoy.
- **PA-8** Duración del bloqueo. Propuesta: 1 día por cada día de retraso, máximo 15, desde el día siguiente a la devolución.
- **PA-9** Métricas del panel. Propuesta: ranking por número de préstamos entregados; ocupación por unidades-día.
- **PA-10** (confirmada) Máximo 3 préstamos en curso por estudiante (RN-04.8); las solicitudes SOLICITADO cuentan (PA-23).
- **PA-11** (confirmada) El estudiante puede cancelar su solicitud mientras todavía pueda resolverse (SOLICITADO hasta el día de inicio; APROBADO hasta que venza su plazo de recogida; después se cierran solas); no hay aprobaciones parciales (SH-07, PA-24).
- **PA-12** (confirmada) Préstamo APROBADO no recogido: al vencer el plazo de recogida el sistema lo pasa automáticamente a RECHAZADO con motivo "No recogido" y notifica a todos los ENCARGADO y al estudiante titular (HU-05e).
- **PA-13** Un préstamo ENTREGADO o VENCIDO con fecha fin pasada retiene unidades desde hoy hasta su devolución (extensión de `CLAUDE.md`). Propuesta: sí.
- **PA-14** Transición VENCIDO -> DEVUELTO (extensión de `CLAUDE.md`). Propuesta: sí.
- **PA-15** Baja de un equipo con solicitudes SOLICITADO. Propuesta: se rechazan automáticamente con motivo "Equipo dado de baja".
- **PA-16** Alertas de vencidos por área (laboratorio, audiovisual, biblioteca). Propuesta: sin filtro; las ven todos los ENCARGADO.
- **PA-17** Estudiante con préstamo VENCIDO sin devolver. Propuesta: no puede solicitar hasta devolver.
- **PA-18** Equipo cuyo total llega a 0 por devolución DAÑADO/PERDIDO y préstamos APROBADO futuros que ya no se pueden cumplir. Propuesta: el equipo se muestra "No disponible", la disponibilidad nunca es negativa y se avisa al encargado. Un APROBADO afectado no se rechaza: ver PA-20.
- **PA-19** (confirmada, modificada por el usuario) Las aprobaciones solo se hacen en horario de servicio (8:00 AM a 5:00 PM). El plazo de recogida son 2 horas de servicio desde la aprobación (o desde las 8:00 AM del día de inicio si se aprobó antes), pudiendo cruzar al día siguiente (RN-05e.2).
- **PA-20** (confirmada) Un préstamo ya APROBADO no se rechaza. Si una devolución con unidades DAÑADO o PERDIDO deja un APROBADO sin cobertura, el encargado solo recibe un aviso, puede reponer unidades, y la entrega se bloquea con "Unidades insuficientes" (RN-05d.4, RN-05b.6); si no se recoge, se cierra como "No recogido".
- **PA-21** (confirmada) La alerta de próximo a vencer también se genera al entregar un préstamo de 2 días el día de inicio (RN-SH06.2); con fecha fin hoy no hay alerta.
- **PA-22** (confirmada, cambiada por el usuario) La aprobación no se bloquea si el plazo de recogida sobrepasa la fecha fin: un préstamo de 1 día aprobado después de las 3:00 PM tiene plazo hasta las 10:00 AM del día siguiente (RN-05a.12, RN-05e.2).
- **PA-23** (confirmada) Las solicitudes SOLICITADO cuentan en el límite de 3 préstamos en curso (convenciones, RN-04.8).
- **PA-24** (confirmada) Cancelación en SOLICITADO (hasta el día de inicio) o APROBADO (hasta que venza su plazo de recogida), siempre antes de la entrega, nuevo estado CANCELADO (extensión del dominio), libera unidades; el motivo es opcional y, si viene vacío, queda "Cancelado por usuario" (SH-07).
- **PA-25** (confirmada) Fecha fin efectiva: si la entrega ocurre después de la fecha fin dentro del plazo (consecuencia de PA-22), la fecha fin efectiva es el día de la entrega. Solo sirve para el vencimiento (RN-SH02.1), el retraso (RN-SH03.1), la alerta (SH-06) y "ENTREGADO dentro de plazo"; no afecta la retención de unidades. Evita sancionar a quien recogió dentro del plazo.
- **PA-26** (confirmada) Las reglas del plazo son distintas según la duración: en préstamos de más de 1 día, una aprobación a las 4:00 PM da plazo hasta las 9:00 AM del día siguiente (la hora restante se cuenta desde las 8:00 AM); en préstamos de 1 día, una aprobación después de las 3:00 PM da plazo hasta las 10:00 AM del día siguiente. Se mantienen ambas tal como están escritas, sin unificar.
- **PA-27** (confirmada) Una SOLICITADO que pasa su fecha de inicio sin resolverse se rechaza sola con el motivo "Sin resolver a tiempo" y se avisa al estudiante (RN-05a.11), para que no ocupe un cupo de los 3 préstamos en curso.
- **PA-28** (confirmada, corregida por el usuario) Rango efectivo de retención de unidades: un ENTREGADO o VENCIDO retiene hasta el día de su devolución; un APROBADO retiene desde su inicio hasta el día en que vence su plazo de recogida o su fecha fin, el que sea posterior. La fórmula de disponibilidad de `CLAUDE.md` ya está alineada con esta decisión.
- **PA-29** (confirmada y cerrada) Baja de cuentas (SH-08): solo el ADMIN; un ADMIN no se da de baja a sí mismo ni da de baja al último ADMIN activo; puede buscar y listar cuentas; el historial se conserva; el correo no vuelve a registrarse. No se da de baja una cuenta cuyo titular tiene préstamos en curso de cualquier tipo (SOLICITADO, APROBADO, ENTREGADO o VENCIDO); no existe cancelación automática por baja de cuenta.
- **PA-30** (confirmada) La sesión de un ADMIN dura como máximo 8 horas, igual que la del ENCARGADO (SH-09). Los tiempos del ESTUDIANTE (1 hora), del ENCARGADO (8 horas) y la ventana de 30 minutos de inactividad los dio el usuario.
- **PA-31** (confirmada) Sesión única (SH-10): aviso "Ya tienes una sesión activa en otro lugar" con las opciones "cerrar la otra sesión" o "cancelar" al ingresar. Además, un ADMIN puede cerrar la sesión de otra cuenta (SH-12). Cerrar otras sesiones desde dentro se eliminó porque no puede prepararse con una sola sesión por usuario.
- **PA-32** (confirmada) Bloqueo por intentos fallidos (SH-11): 3 intentos fallidos consecutivos (sin ningún inicio exitoso entre medias y sin ventana de tiempo; el contador se reinicia con un inicio exitoso o al terminar el bloqueo), 15 minutos de bloqueo, contador también para correos sin cuenta, y un límite por origen de conexión de 10 intentos fallidos cada 15 minutos con el mensaje "Demasiados intentos. Inténtalo de nuevo más tarde". Regla general: todos los fallos de inicio de sesión devuelven "Credenciales inválidas" sin revelar si el correo existe ni qué dato es correcto.
- **PA-33** (confirmada) Textos para sesiones abiertas: "Tu sesión ya no es válida. Inicia sesión de nuevo" (cuenta dada de baja o sesión cerrada por un ADMIN) y "Tu sesión fue cerrada porque iniciaste sesión en otro lugar" (sesión desplazada).
- **PA-34** (confirmada) El registro (RN-01a.2) puede indicar que ya existe una cuenta asociada a ese correo; es una limitación aceptada por el usuario frente a la regla general de no revelar la existencia de cuentas, que aplica solo al inicio de sesión.
- **PA-35** (confirmada) Límite por origen (SH-11): la ventana de 15 minutos empieza en el primer intento fallido de la serie y, al décimo fallo, el origen queda bloqueado hasta que se cumplan 15 minutos desde ese primer fallo.
- **PA-36** (confirmada) Mensaje de rechazo de la baja de una cuenta con préstamos en curso (SH-08): "La cuenta tiene préstamos en curso".

---

## Registro de revisión

Nota: todos los estados "pendiente de confirmar" de las filas de las rondas 1 a 14 quedaron confirmados por el usuario en rondas posteriores (hoy no queda ninguna decisión pendiente; la ronda 14c cierra PA-36). La ronda 9c deja superadas las filas de la ronda 6 con "pendiente de confirmar (PA-25, PA-26)" y "pendiente de confirmar (PA-27)", y la ronda 10 las filas de las rondas 7, 8 y 9b con "pendiente de confirmar (PA-28)". y las referencias a un cierre manual de préstamos no recogidos y a HU-05c con daños (hoy HU-05d) están superadas por la ronda 4. Las referencias "RN-05c.2 a RN-05c.4", "RN-05c.7", "RN-05c.8" y "RN-05c.9" de las rondas 1 y 2 corresponden a la numeración de la ronda 2; hoy equivalen a RN-05c.2 a RN-05c.4 (devolución), RN-05d.3 y RN-05d.4 (total en 0 y aviso) y RN-05c.7 (casos VENCIDO). Los escenarios "2b" a "2e" de HU-05c de la ronda 2 son hoy los escenarios 2 a 5 de HU-05d.

| Ronda | Hallazgos atendidos | Estado |
|---|---|---|
| 0 | Versión inicial (alcance readme 1.1 y 1.2). | Superada |
| 1 | B1 VENCIDO retiene unidades: decidida opción A como propuesta (RN-03.2, RN-02a.5, RN-SH02.3, escenario 4 de HU-03, PA-13). | Atendido, pendiente de confirmar |
| 1 | B2 VENCIDO -> DEVUELTO declarada extensión del dominio (convenciones, RN-05c.1, escenario 5 de HU-05c, PA-14). | Atendido, pendiente de confirmar |
| 1 | B3 competencia por la última unidad: eliminada de HU-04, resuelta al aprobar (RN-05a.3, escenario 4 de HU-05a). | Atendido |
| 1 | B4 dependencia Must -> Should: bloqueo de SH-03 retirado de HU-04 y expresado solo en SH-03 (RN-SH03.7). | Atendido |
| 1 | B5 estados del equipo DISPONIBLE y MANTENIMIENTO con efecto en búsqueda, disponibilidad y solicitud (RN-02a.4, RN-03.4, RN-04.6, escenarios). | Atendido |
| 1 | B6 unidades comprometidas definidas y escenario con fechas (RN-02a.5, escenario 4 de HU-02a). | Atendido |
| 1 | B7 baja: estados que bloquean y tratamiento de SOLICITADO (RN-02b.2, RN-02b.3, escenario 3; PA-15). HU-02 dividida en 02a y 02b. | Atendido, pendiente de confirmar |
| 1 | B8 escenario con 0 unidades (HU-02a, escenario 3). | Atendido |
| 1 | B9 valores concretos de dominio y contraseña y escenarios (RN-01a.1, RN-01a.3; PA-1, PA-3). | Atendido, pendiente de confirmar |
| 1 | B10 alta de roles: regla de carga inicial y escenarios (RN-01a.4, escenario 5 de HU-01b; PA-2). | Atendido, pendiente de confirmar |
| 1 | B11 rango con extremos incluidos, ejemplos 10-16 y 10-17, y definición de cruce (convenciones comunes, escenario 2 de HU-03). | Atendido |
| 1 | B12 antelación y escenarios de fecha inválida (RN-04.2, escenarios 5 y 6; PA-4). | Atendido, pendiente de confirmar |
| 1 | B13 camino feliz del rechazo y aprobar algo no pendiente (HU-05a, escenarios 2 y 6). | Atendido |
| 1 | B14 estados de devolución y efecto en unidades, escenario de equipo dañado (RN-05c.2 a RN-05c.4; PA-6). | Atendido, pendiente de confirmar |
| 1 | B15 duración del bloqueo con valores y fechas (RN-SH03.1, escenarios 1 y 2; PA-8). | Atendido, pendiente de confirmar |
| 1 | B16 estudiante con VENCIDO sin devolver (RN-SH03.5, escenario 6; PA-17). | Atendido, pendiente de confirmar |
| 1 | B17 métricas definidas, datos concretos y escenarios de ocupación y vencidos (RN-SH04.1 a RN-SH04.4; PA-9). | Atendido, pendiente de confirmar |
| 1 | M1 a M4: beneficio reformulado, registro y login separados (HU-01a, HU-01b), sin "pantalla/menús". | Atendido |
| 1 | M5 y M6: escenarios de rango invertido y fecha pasada; búsqueda parcial y por categoría (HU-03). | Atendido |
| 1 | M7 a M9: "se registra completa o no se registra", fechas relativas en HU-04; tamaño reevaluado tras quitar reglas, se mantiene una sola historia. | Atendido |
| 1 | M10 a M13: HU-05 dividida en 05a, 05b, 05c; escenario con números; ventana de entrega (RN-05b.3, PA-12); longitud del motivo (PA-5). | Atendido |
| 1 | M14: revisión diaria a las 00:05, cierre de alerta y filtro por área (RN-SH02.1, RN-SH02.5; PA-16). | Atendido |
| 1 | M15 y M16: redacción corregida; escenario 1 de SH-03 sin depender de SH-02; acumulación de bloqueos (RN-SH03.6). | Atendido |
| 1 | M17 y M18: fecha de referencia del filtro y escenario (SH-01); columnas, filtros opcionales y fecha (SH-05). | Atendido |
| 1 | M19: índice justifica Should vs Must y enlaza PA-10 y PA-11. M20: mensajes alineados con la sección 5 del readme. | Atendido |
| 2 | R1 retención independiente de VENCIDO: ENTREGADO con fecha fin pasada retiene unidades (convenciones, RN-03.2, escenario 4 de HU-03, escenario 5 de HU-05c); casos VENCIDO declarados como aplicables con SH-02 (RN-05c.9, escenario 5b). | Atendido, pendiente de confirmar (PA-13) |
| 2 | R2 total en 0 por devolución: RN-02a.3 limitada a crear/editar, RN-02a.6 a edición manual, RN-05c.7 y RN-05c.8, escenarios 2d y 2e, disponibilidad nunca negativa (escenario 4b de HU-03). | Atendido, pendiente de confirmar (PA-18) |
| 2 | R3 el estudiante ve sus solicitudes y el motivo en HU-04 (RN-04.7, escenarios 10 y 11); SH-01 queda solo con filtros; índice ajustado. | Atendido |
| 2 | R4 ocupación independiente de la fecha de inicio (RN-SH04.1 y RN-SH04.4, escenario 3b). | Atendido |
| 2 | m1 y m2: regla de fecha pasada limitada a HU-03/HU-04 y definición de préstamo activo en convenciones. m3 y m4: rol "Todos los roles" y escenarios de HU-01b sin función concreta. | Atendido |
| 2 | m5, m8, m9: MANTENIMIENTO y rango terminado en HU-05a (RN-05a.7, RN-05a.8, escenarios 8 y 9); cantidad 0 en HU-04 (escenario 9). m6: escenario multi-equipo con baja en HU-02b. | Atendido |
| 2 | m7: cierre de APROBADO no recogido (RN-05b.6, escenario 7; PA-12). m10: esc. 4 de HU-05a con un solo When. m11: escenario 6 de HU-05b. | Atendido, pendiente de confirmar (PA-12) |
| 2 | m12 y m13: estado de devolución por cantidad por estado, escenarios mixto y de suma incorrecta, fecha/hora/encargado en el Then del esc. 1 de HU-05c. | Atendido |
| 2 | m14 a m16: historia de SH-03 reformulada, mensaje con fecha de reanudación, escenario 3b de solapamiento, RN-SH03.7 pasada a nota, dependencia de SH-02 declarada y esc. 2 con ENTREGADO. | Atendido |
| 3 | n3 convención "ENTREGADO dentro de plazo"; n4 definición de "equipo activo" (usada en SH-04); n5 duplicado entre HU-04 y SH-01 eliminado (el estado y el motivo solo se describen en HU-04); n6 RN-05a.7 limitada a MANTENIMIENTO; n7 título de HU-05b ampliado; n8 referencias del registro marcadas como superadas por la nota inicial. | Atendido |
| 3 | n2 HU-05c dividida en devolución básica (HU-05c) y devolución con daños o pérdidas (HU-05d), con reglas RN-05d.x y escenarios propios; n1 PA-18 queda como decisión del encargado (RN-05d.4), sin transición automática. | Atendido |
| 4 | Decisiones confirmadas por el usuario: PA-1 a PA-9 y PA-12 a PA-18 sin "pendiente de confirmar"; VENCIDO retiene unidades, VENCIDO -> DEVUELTO válido, titular = quien solicita. | Atendido |
| 4 | PA-12: inicio de servicio 8:00 AM como convención común; entrega solo de 8:00 a 9:59 AM del primer día; cierre automático a las 10:00 AM como RECHAZADO "No recogido" (RN-05b.3, RN-05b.6); escenarios con 10:00 exactas, 9:59 y 7:59; HU-02b, HU-05a y SH-04 ajustadas al cierre automático. | Atendido y confirmado |
| 4 | Notificación al ENCARGADO y al estudiante titular al cerrarse un préstamo como "No recogido" (RN-05b.8, escenarios 7b y 7c). | Atendido y confirmado |
| 4 | SH-02: alerta de "próximo a vencer" para el estudiante titular un día antes de la fecha fin (RN-SH02.6 a RN-SH02.8, escenarios 6 a 9), sin depender de SH-03. | Atendido |
| 4 | Nuevo PA-19: aprobación tardía el día de inicio (RN-05b.7, escenario 9 de HU-05b). | Pendiente de confirmar |
| 4b | X1 RN-05a.8 cambiada a "inicio anterior a hoy"; escenarios 9 y 10 de HU-05a (mensaje "La solicitud ya inició"; inicio hoy lo regula RN-05b.7). | Atendido |
| 4b | X2 rechazo de APROBADO afectado (RN-05a.10, escenario 11 de HU-05a) y bloqueo de entrega sin unidades (RN-05b.9, escenario 11 de HU-05b); RN-05d.4 alineada. | Atendido, pendiente de confirmar (PA-20) |
| 4b | X3 RN-05b.3 con "salvo RN-05b.7"; escenarios 9 y 10 de HU-05b (cierre a la 1:00 PM y entrega a las 12:00 PM). X6 notificación a todos los ENCARGADO (RN-05b.8). X7 escenario 6 con hora. | Atendido |
| 4b | X4 y X5 la alerta de próximo a vencer pasa de SH-02 a la nueva SH-06 (la fila de la ronda 4 que la ubica en RN-SH02.6 a RN-SH02.8 queda superada); dependencia de SH-03 declarada; alerta al entregar préstamos cortos (RN-SH06.2, escenarios 5 y 6). | Atendido, pendiente de confirmar (PA-21) |
| 4b | X8 reglas pegadas separadas en HU-01a, HU-05a y SH-03; RN-05b.6 a RN-05b.8 ordenadas. X9 aclarada la numeración de referencias de rondas anteriores. | Atendido |
| 5 | Nota de numeración: las filas de las rondas 4 y 4b que citan RN-05b.6 a RN-05b.9 y los escenarios 7 a 10 de HU-05b se refieren a la numeración anterior; esas reglas hoy son RN-05e.1 a RN-05e.3 (cierre, plazo, notificación) y RN-05b.6 (unidades insuficientes), y esos escenarios están en HU-05e. | Aclarado |
| 5 | PA-10 confirmada: límite de 3 préstamos en curso (RN-04.8, escenarios 12 a 14 de HU-04); "préstamo en curso" definido en convenciones; PA-23 propone que SOLICITADO cuente. | Atendido, pendiente de confirmar (PA-23) |
| 5 | PA-11 confirmada: nueva SH-07 para cancelar (SOLICITADO o APROBADO antes de la entrega, estado CANCELADO, libera unidades, motivo opcional) sin aprobaciones parciales; estado CANCELADO añadido a retención, HU-03 y SH-01. | Atendido, pendiente de confirmar (PA-24) |
| 5 | PA-19 modificada: horario de servicio 8:00 AM a 5:00 PM, aprobación solo en horario (RN-05a.10), plazo de recogida de 2 horas de servicio que puede cruzar de día (convenciones, RN-05b.3, RN-05e.2); escenarios 11:00 AM, 4:00 PM y 5:00 PM; fuera de horario bloqueado. Resuelve la ventana nocturna (Y3). | Atendido y confirmado |
| 5 | PA-20 cambiada: se elimina el rechazo de APROBADO (RN-05a.10 anterior y su escenario); RN-05a.3 reforzada; RN-05d.4 solo informa y la salida es la entrega bloqueada (RN-05b.6) y el cierre "No recogido" (Y4). Nuevo PA-22: plazo que exceda la fecha fin impide aprobar (RN-05a.11). | Atendido, pendiente de confirmar (PA-20, PA-22) |
| 5 | PA-21 confirmada y RN-SH06.2 limitada a préstamos de 2 días entregados el día de inicio (Y5). PA-12 reconfirmada. | Atendido y confirmado |
| 5 | Y7 mensajes distintos "La solicitud ya terminó" y "La solicitud ya inició" (RN-05a.8); Y2 excepción de aprobación tardía en convenciones (plazo de recogida); Y6 HU-05b dividida en entrega (HU-05b) y cierre automático (HU-05e). | Atendido |
| 6 | PA-20, PA-23 y PA-24 confirmadas; PA-22 cambiada: la aprobación no se bloquea si el plazo sobrepasa la fecha fin (RN-05a.12 en lugar del bloqueo anterior, escenarios 14 y 15 de HU-05a a las 3:01 PM y 5:00 PM; RN-05e.2 y RN-05e.5, escenarios 5b a 5e de HU-05e a las 3:00 PM, 3:01 PM, 10:00 AM y medianoche). | Atendido y confirmado |
| 6 | Consecuencias de PA-22: fecha fin efectiva si se entrega tras la fecha fin (convenciones, RN-05b.3, escenario 10b de HU-05b, hoy escenario 11; PA-25) y posible contradicción entre la excepción de 1 día y la regla general del plazo (PA-26). | Atendido, pendiente de confirmar (PA-25, PA-26) |
| 6 | Z1 rechazo automático "Sin resolver a tiempo" (RN-05a.11, escenario 16 de HU-05a; PA-27) y cupo liberado por RECHAZADO y CANCELADO (escenarios 15 y 16 de HU-04). | Atendido, pendiente de confirmar (PA-27) |
| 6 | PA-24: motivo vacío queda "Cancelado por usuario" (RN-SH07.5, escenarios 1 y 1b de SH-07); PA-11 y convenciones con "antes de la entrega". Z2 PA-18 remite a PA-20; Z3 índice con HU-05a a HU-05e; Z8 escenario 4b de SH-07 (RECHAZADO y CANCELADO). Z4 y Z5 resueltos con lo anterior. | Atendido |
| 7 | W1 contradicción de retención resuelta con un rango efectivo de retención (APROBADO: desde su inicio hasta el día en que vence su plazo de recogida o su fecha fin, el que sea posterior; ENTREGADO: hasta su fecha fin efectiva; VENCIDO: hasta la devolución) usado en las convenciones, RN-03.2, RN-05a.3 y RN-05e.5; escenarios 4c de HU-03 y 17 y 18 de HU-05a (1 unidad, préstamo B del 11 y aprobación de A a las 5:00 PM del 10). Afecta la fórmula de disponibilidad de `CLAUDE.md` (PA-28). | Atendido, pendiente de confirmar (PA-28) |
| 7 | W2 "fecha fin efectiva" en RN-SH03.1, RN-SH02.1 y en la convención "ENTREGADO dentro de plazo"; escenario 7 de SH-03 (entregado el 11 tras plazo cruzado y devuelto el 11, sin bloqueo). | Atendido |
| 7 | W3 (Z6) RN-05b.3 con "las 8:00 AM del día de inicio o la hora de aprobación si es posterior"; W4 (Z7) escenarios de HU-05b renumerados de 1 a 12; W5 (Z9) quitado "antes de las 8:00 AM" y "antes de esa hora" de las convenciones y RN-05e.2. Z6, Z7 y Z9 corregidos en esta ronda. | Atendido |
| 7 | W6 fila de la ronda 5 (Y7, Y2, Y6) movida a su sitio cronológico. | Atendido |
| 8 | V1 RN-05a.3 reescrita: compara contra el rango efectivo que tendría la solicitud al aprobarse ahora (desde su inicio hasta el día en que vencería su plazo o su fecha fin, el que sea posterior); misma aclaración en la convención. Con esto el escenario 17 de HU-05a (A del 10 contra B del 11) se bloquea correctamente. | Atendido |
| 8 | V2 la convención usa el rango efectivo en HU-03, HU-05a y SH-04 (se quitó HU-05b, cuya RN-05b.6 compara el total con la cantidad). V3 RN-SH06.1 a RN-SH06.3 con "fecha fin efectiva". V4 RN-SH04.4 usa el rango efectivo de retención en las unidades-día. | Atendido, pendiente de confirmar (PA-28) |
| 8 | V5 equivalencia de numeración de HU-05b en el registro: lo que las rondas 4b, 5 y 6 llaman escenarios 4b, 5, 6, 10b y 11 hoy son los escenarios 5, 6, 7, 11 y 12. V6 coma corregida en el encabezado. | Atendido |
| 9b | PA-28 corregida por el usuario: un ENTREGADO o VENCIDO retiene unidades hasta ser DEVUELTO (convenciones, RN-03.2, RN-SH04.4). La fecha fin efectiva (PA-25) no afecta la retención y solo sirve para vencimiento, retraso, alerta y "ENTREGADO dentro de plazo"; PA-25 simplificada. RN-05a.3 y RN-05e.5 siguen válidas porque remiten al rango efectivo. Escenarios nuevos: 5a de HU-05c (la devolución libera la retención) y 3c de SH-04 (ENTREGADO sin devolver cuenta hasta hoy: 14%); el 3b de SH-04 usa ahora un préstamo devuelto. Los escenarios 4 de HU-03, 17 y 18 de HU-05a y 7 de HU-05b ya eran coherentes. Las filas de la ronda 7 y 8 que dicen "ENTREGADO hasta su fecha fin efectiva" quedan superadas. | Atendido, parte del APROBADO pendiente de confirmar (PA-28) |
| 9c | PA-25, PA-26 y PA-27 confirmadas por el usuario: quitado "pendiente de confirmar" en convenciones, RN-05a.11, encabezado, lista de PAs y estados. | Atendido y confirmado |
| 10 | PA-28 confirmada completa (incluido el APROBADO): quitado "pendiente de confirmar" en la convención, la lista de PAs, el encabezado y el registro. Ya no queda ninguna PA pendiente. | Atendido y confirmado |
| 10 | U1 escenario 3c de SH-04 con fechas de inicio y fin (30 de octubre al 5 de noviembre); el 14% se verifica: 7 unidades-día del 1 al 7 de noviembre entre 50. U2 convención: el ENTREGADO o VENCIDO retiene desde su inicio hasta el día de su devolución y para la disponibilidad solo importan los días desde hoy. | Atendido |
| 10 | U3 nota inicial del registro con las filas superadas por la ronda 9c. U4 quitada la frase de que `CLAUDE.md` debe alinearse (ya está alineado) y lista de preguntas ordenada numéricamente (PA-26 a PA-28 tras PA-25). U5 "(fecha fin efectiva)" en RN-SH02.4 y RN-SH06.4. | Atendido |
| 11 | Nuevas historias de autenticación y administración pedidas por el usuario: SH-08 baja de cuentas (Should), SH-09 duración y expiración de la sesión (Should), SH-11 bloqueo temporal por intentos fallidos (Should) y SH-10 sesión única por usuario (Could, nueva sección Could). HU-01b no crece: solo añade RN-01b.5 que remite a ellas. Índice actualizado. | Atendido, pendiente de confirmar (PA-29 a PA-32) |
| 11 | Decisiones propuestas: ADMIN con sesión de 8 horas (PA-30); mensajes y opciones de sesión única (PA-31); 3 intentos y 15 minutos de bloqueo con mensaje genérico (PA-32); restricciones de la baja de cuentas y cancelación automática con "Cuenta dada de baja" (PA-29). | Pendiente de confirmar |
| 11b | K1 y K7: SH-10 sin RN-SH10.4 ni los escenarios de cerrar sesiones desde dentro; "cerrar la otra sesión" al ingresar cubre ese caso; escenario 4 nuevo (sin otra sesión); SH-10 pasa de Could a Should y se quita la sección Could (índice y orden actualizados). | Atendido |
| 11b | K2: RN-01b.2 y escenario 2 de HU-01b indican que el mensaje "Credenciales inválidas" rige mientras no exista SH-11 y que SH-11 lo sustituye por su mensaje genérico (dependencia declarada en SH-11). K4: "Tu cuenta no está activa" solo con la contraseña correcta; con contraseña equivocada rige el mensaje genérico y el intento cuenta (RN-SH08.2, RN-SH11.7, escenario 6 de SH-11). | Atendido |
| 11b | K3: SH-09, SH-10 y SH-11 con "Como ESTUDIANTE, ENCARGADO o ADMIN" y rol "Todos los roles" en el índice. K5: SH-08 declara su dependencia de SH-07 y RN-SH07.1 exceptúa la cancelación del sistema por baja de cuenta. | Atendido |
| 11b | K6: corte inmediato tras la baja para renovar sesión y acciones que modifican datos, y hasta 15 minutos para consultas ya autorizadas (RN-SH09.4, escenarios 5 y 5b de SH-09; superado en la ronda 15: el corte es inmediato para todas las acciones). K9: RN-SH08.1 permite dar de baja cualquier cuenta salvo el único ADMIN activo; Then observable del escenario 1 y escenario 4b (baja de ENCARGADO). | Atendido |
| 11b | K8: encabezado reescrito con el alcance actual (Must y Should) y sin conteos obsoletos ni frases repetidas. K10: "3 intentos fallidos consecutivos" = sin inicio exitoso entre medias y sin ventana de tiempo, con reinicio por inicio exitoso o fin del bloqueo (RN-SH11.1, PA-32). | Atendido, pendiente de confirmar (PA-32) |
| 13 | A. Regla general de inicio de sesión: un único mensaje "Credenciales inválidas" para credenciales incorrectas, correo inexistente, cuenta dada de baja y cuenta bloqueada (RN-01b.2, RN-SH11.2, RN-SH11.7, RN-SH08.2; escenarios 2b de HU-01b, 1, 2, 5 y 6 de SH-11, 1 y 4 de SH-08). "Tu cuenta no está activa" y el texto largo de SH-11 desaparecen del inicio de sesión; para sesiones ya abiertas se usa "Tu sesión ya no es válida. Inicia sesión de nuevo" (RN-SH09.4, escenarios 5 y 5b). Las filas de la ronda 11b que citan "Tu cuenta no está activa" quedan superadas. | Atendido, textos pendientes de confirmar (PA-33) |
| 13 | A. PA-34 anotada: el registro (RN-01a.2) sigue revelando correos existentes. | Atendido, abierta (PA-34) |
| 13 | B. PA-30, PA-31 y PA-32 confirmadas. Nueva SH-12 (el ADMIN cierra la sesión de otra cuenta); SH-08 con búsqueda y listado de cuentas (RN-SH08.7), "Usuario no encontrado" solo para el ADMIN, y mensajes "No puedes darte de baja a ti mismo" y "Debe existir al menos un administrador activo" (RN-SH08.1, escenarios 6 a 6e); SH-11 con límite por origen de 10 intentos fallidos cada 15 minutos y mensaje "Demasiados intentos. Inténtalo de nuevo más tarde" (RN-SH11.8, escenarios 7 y 8); SH-10 con texto de sesión desplazada; SH-09 con escenario de sesión de 8 horas del ADMIN. | Atendido y confirmado |
| 13 | C. SH-07: la cancelación solo se permite mientras la solicitud pueda resolverse (SOLICITADO hasta el día de inicio; APROBADO hasta que venza su plazo de recogida), con escenarios 2b a 2d; PA-11 y PA-24 alineadas. RN-02b.3 se verifica: la baja de un equipo rechaza las SOLICITADO con su propio motivo "Equipo dado de baja", que prevalece sobre "Sin resolver a tiempo". | Atendido |
| 13 | D. PA-29 queda pendiente de confirmar solo en el punto de los préstamos en curso de una cuenta dada de baja (RN-SH08.3 y RN-SH08.4); el resto de PA-29 está confirmado. | Atendido, pendiente de confirmar (PA-29, un punto) |
| 13b | I2 RN-SH09.4 en lenguaje de negocio: tras la baja, las acciones que modifican datos se rechazan de inmediato; las consultas de ENCARGADO y ADMIN también se cortan de inmediato y las del ESTUDIANTE a más tardar 15 minutos después (escenario 5b2 con un ENCARGADO; superado en la ronda 15: el corte es inmediato para todos los roles y todas las acciones). I3 SH-12 cierra todas las sesiones activas de la cuenta, con corte inmediato (RN-SH12.3). I4 SH-08 declara también su dependencia de SH-09. | Atendido |
| 13b | I5 entre las 00:00 y las 00:05 del día siguiente al de inicio una SOLICITADO no se cancela (RN-SH07.2, escenario 2c2 de SH-07). I6 índice con el mismo orden que el cuerpo (SH-08, SH-10, SH-12) y lista de PAs ordenada. I7 RN-SH08.1 fija que, si coinciden autobaja y último ADMIN, se muestra "Debe existir al menos un administrador activo". | Atendido |
| 13b | I8 el límite por origen es una ventana de 15 minutos desde el primer fallo de la serie (RN-SH11.8, escenarios 7 y 8). I1 PA-29 sigue pendiente solo en el punto de préstamos en curso. | Atendido, pendiente de confirmar (PA-35) |
| 14 | SH-08: la baja no se permite con préstamos en curso de cualquier tipo (SOLICITADO, APROBADO, ENTREGADO o VENCIDO); mensaje "La cuenta tiene préstamos en curso" (RN-SH08.3, escenarios 2 y 3). Eliminada la cancelación automática "Cuenta dada de baja" (RN-SH08.4 ahora dice que la baja no modifica préstamos), la dependencia de SH-07 (índice y encabezado de SH-08) y la excepción de RN-SH07.1: CANCELADO solo lo produce el estudiante. Las filas de las rondas 11, 11b y 13 que mencionan esa cancelación o la dependencia de SH-07 quedan superadas. Verificado sin contradicciones con el límite de 3, la retención de unidades y CANCELADO. SH-08 conserva 11 escenarios. | Atendido, mensaje pendiente de confirmar (PA-36) |
| 14 | PA-29 confirmada y cerrada con la regla anterior. PA-34 confirmada: el registro puede indicar "Ya existe una cuenta asociada a ese correo" (RN-01a.2 y escenario 2 de HU-01a); deja de ser pregunta abierta. | Atendido y confirmado |
| 14b | PA-33 (textos "Tu sesión ya no es válida. Inicia sesión de nuevo" y "Tu sesión fue cerrada porque iniciaste sesión en otro lugar") y PA-35 (ventana de 15 minutos desde el primer fallo de la serie para el límite por origen) confirmadas por el usuario: quitado "pendiente de confirmar" en RN-SH09.4, RN-SH10.3, RN-SH11.8, RN-SH12.3, encabezado, estado y lista de PAs. Las filas de las rondas 11, 13 y 13b que las marcan como pendientes quedan superadas. | Atendido y confirmado |
| 14c | PA-36 confirmada ("La cuenta tiene préstamos en curso"): quitado "pendiente de confirmar" en RN-SH08.3, encabezado, estado y lista de PAs. Ya no queda ninguna PA pendiente ni abierta; todas las filas anteriores con "pendiente de confirmar" quedan superadas. H2: el escenario 2 de SH-08 se separa en el escenario 2 (ENTREGADO) y el 2b (VENCIDO). Fila 14b reordenada tras la ronda 14. | Atendido y confirmado |
| 15 | Decisión del usuario: tras una baja de cuenta o un cierre administrativo de sesión, el acceso se corta de inmediato para todos los roles y todas las acciones, incluidas las consultas del ESTUDIANTE. Eliminada la ventana de "a más tardar 15 minutos": RN-SH09.4 reescrita, escenario 5b rehecho sin tiempo de espera, RN-SH08.2 y RN-SH12.3 alineadas con "de inmediato" y nuevo escenario 1b de SH-12 (consulta inmediata tras el cierre). Las filas de las rondas 11b y 13b que citan el margen de 15 minutos quedan superadas. | Atendido y confirmado |
| 15b | G1 el Then del escenario 5b2 de SH-09 (ENCARGADO) termina también en "y la sesión se cierra". G2 RN-SH10.3 dice que el corte de la sesión desplazada es inmediato para todas las acciones. | Atendido |
