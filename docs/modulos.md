# Especificación de Módulos del Sistema y Contratos de Interfaz

Este documento define la arquitectura modular del sistema **Gym Manager**, detallando para cada componente sus objetivos específicos, las entidades del modelo de datos involucradas, los Requerimientos Funcionales (RF) y los contratos formalizados de interfaz REST.

---

**Estado de implementación:** este documento especifica contratos y comportamientos objetivo; su inclusión aquí no afirma que los endpoints, controladores o pantallas estén implementados.

**Roles:** `ADMIN` es el encargado o dueño del gimnasio y `STAFF` es el personal operativo, como recepción y caja. Cada contrato indica qué roles pueden usarlo; si lo llama un usuario con otro rol, la respuesta es `403 Forbidden`. El login, la confirmación de Mercado Pago y la tarea diaria de avisos no los llama un empleado con rol.

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`AuthController`, `AuthService`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `Employee` (`employees`), `Person` (`persons`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-01** | `POST` | `/api/auth/login` | Sin token | Autentica credenciales de usuario (email de trabajo `work_email` y contraseña) y devuelve un token Bearer JWT con los roles asignados. | `{"work_email": "admin@gym.com", "password": "..."}` | `200 OK` (token JWT y datos de sesión), `401 Unauthorized` (credenciales inválidas), `403 Forbidden` (usuario inactivo). |

**Reglas de Negocio Formales:**
1. **Personal Autorizado:** Solo los empleados registrados con rol `ADMIN` o `STAFF` cuya cuenta laboral se encuentre activa tienen autorización para acceder a las funciones protegidas del sistema.
2. **Autoridad y Permisos Vigentes:** Los permisos de acceso se evalúan según el rol y la condición activa vigentes en cada operación. La degradación de privilegios o la desactivación de una cuenta laboral surten efecto inmediato sobre solicitudes posteriores. La modificación de credenciales de acceso no interrumpe sesiones ya iniciadas con anterioridad hasta su caducidad o desactivación de la cuenta.

**Notas Técnicas del Contrato:**
- La autenticación de `RF-01` expide un token `Bearer JWT` firmado digitalmente (`HMAC-SHA256`) que contiene el código de empleado y el alcance de aplicación (`scope: PANEL` o `scope: TERMINAL`).
- En cada solicitud a endpoints protegidos, el backend valida la firma del token y consulta por clave primaria (`SELECT active, role FROM employees WHERE employee_code = ?`) el estado y rol vigentes: si el empleado fue desactivado o ya no existe se responde `401 Unauthorized`; si carece del rol necesario para la ruta requerida se responde `403 Forbidden`, resolviendo la autorización contra la base y no contra el token emitido.
- La arquitectura stateless sin lista negra de revocación implica que el cambio de contraseña no invalida de inmediato tokens emitidos previamente, caducando por expiración natural o al desactivar la cuenta laboral (`active = false`). Fundamentado en [ADR-0012](./adr/ADR-0012-autenticacion-stateless-jwt-segregacion-alcance-dual.md).
---

### 1.2. Módulo Actors: Members & Employees (`MemberController`, `EmployeeController`)

- **Objetivos:** Administrar el ciclo de vida de los actores del sistema. Diferencia conceptualmente la gestión de socios deportivos (`Member`) del personal administrativo y operativo (`Employee`). Los dos son roles de una `Person`, que guarda los datos personales y legales; una misma persona puede tener uno o los dos.
- **Entidades involucradas:** `Person` (`persons`), `Member` (`members`), `Employee` (`employees`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-02** | `GET` | `/api/members` | `ADMIN`, `STAFF` | Listado paginado de socios con soporte de filtros por estado (`status`: `ACTIVE`, `INACTIVE`). | Query params: `page`, `size`, `status` | `200 OK` (lista paginada). |
| **RF-03** | `GET` | `/api/members/{member_number}` | `ADMIN`, `STAFF` | Obtiene la ficha de un socio a partir de su clave primaria natural de negocio (`member_number`). | Path param: `member_number` | `200 OK` (objeto MemberDTO), `404 Not Found`. |
| **RF-04** | `POST` | `/api/members` | `ADMIN`, `STAFF` | Da de alta el rol de socio con su `member_number` único. Si el DNI no está registrado, primero se crea la `Person` (contacto obligatorio) y después el `Member`; si ya está registrado, se usa esa persona y solo se crea el `Member`. | `{"member_number": "1001", "dni": "...", "name": "...", "lastName": "...", "email": "...", "phone": "..."}` | `201 Created` (MemberDTO creado), `400 Bad Request` (validación fallida), `409 Conflict` (número de socio ya existente o la persona ya es socia). |
| **RF-05** | `PUT` | `/api/members/{member_number}` | `ADMIN`, `STAFF` | Actualiza datos de contacto o personales de un socio existente. | Path param: `member_number`. Body con campos actualizables. | `200 OK`, `400 Bad Request`, `404 Not Found`. |
| **RF-06** | `POST` | `/api/members/{member_number}/status` | `ADMIN`, `STAFF` | Cambia el estado de membresía del socio (`ACTIVE`, `INACTIVE`). | Path param: `member_number`. Body: `{"status": "INACTIVE"}` | `200 OK`, `404 Not Found`. |
| **RF-07** | `GET` | `/api/employees` | `ADMIN` | Listado de empleados del gimnasio para administración de personal. | Query params: `page`, `size`, `role` | `200 OK`. |
| **RF-08** | `POST` | `/api/employees` | `ADMIN` | Da de alta el rol de empleado con credenciales de login (`work_email`, `password`) y rol operativo (`ADMIN`, `STAFF`). Si el DNI no está registrado, primero se crea la `Person` y después el `Employee`; si ya está registrado, se usa esa persona y solo se crea el `Employee`. | `{"employee_code": "EMP01", "dni": "...", "name": "...", "lastName": "...", "work_email": "admin@gym.com", "email": "...", "phone": "...", "password": "...", "role": "STAFF"}` | `201 Created`, `400 Bad Request`, `409 Conflict` (código de empleado o work_email ya existente, o la persona ya es empleada). |
| **RF-09** | `PUT` | `/api/employees/{employee_code}` | `ADMIN` | Actualiza datos personales o de contacto, `work_email`, rol o contraseña de un empleado existente. El `employee_code` no se cambia. | Path param: `employee_code`. Body con campos actualizables. | `200 OK`, `400 Bad Request`, `404 Not Found`, `409 Conflict` (work_email ya usado por otro empleado). |
| **RF-10** | `POST` | `/api/employees/{employee_code}/status` | `ADMIN` | Activa o desactiva la cuenta de un empleado (`active`). Un empleado desactivado no puede iniciar sesión (regla 1 de Auth), y los cobros que hizo siguen a su nombre. | Path param: `employee_code`. Body: `{"active": false}` | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Canal de contacto mínimo (Privacy & Contact):** Es estrictamente obligatorio registrar al menos un canal de contacto válido (email o teléfono) en la persona base, garantizando la viabilidad de notificaciones.
2. **Aislamiento de Credenciales:** Los socios (`Member`) no poseen contraseña ni rol administrativo en V1. Las credenciales de acceso residen de forma exclusiva en `Employee`.
3. **Número de Socio como Identificador Operativo:** El `member_number` es la clave primaria natural del socio para toda interacción de mostrador y terminal de acceso, resguardando el DNI como dato netamente civil y administrativo.
4. **Segregación Semántica de Email:** El correo electrónico civil y de contacto (`persons.email`) no es único y está destinado a la comunicación familiar, permitiendo que menores de edad compartan el correo de sus tutores sin generar conflictos (`409 Conflict`). En contrapartida, la credencial de login y autenticación reside de forma unívoca y obligatoria en el correo corporativo del empleado (`employees.work_email`), garantizando cuentas de acceso individuales, no transferibles y trazables.
5. **Sumar un rol a una persona existente:** Al dar de alta un socio o un empleado, si el DNI ya está registrado en `persons` se usa esa persona y solo se crea el rol nuevo, sin duplicar sus datos personales ni modificarlos. Por ejemplo, una profesora que ya es empleada puede darse de alta como socia con su mismo DNI. Una persona no puede tener dos veces el mismo rol (`members.dni` y `employees.dni` son únicos).

### 1.3. Módulo Subscriptions (`SubscriptionController`, `SubscriptionService`)

- **Objetivos:** Gestionar los períodos de suscripción de los socios, vinculando el plan seleccionado mediante `plan_code`, estableciendo la vigencia temporal (`start_date`, `end_date`) y consultando `plans.weekly_limit` para el cupo semanal.
- **Entidades involucradas:** `Subscription` (`subscriptions`), `Member` (`members`), `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-11** | `GET` | `/api/subscriptions` | `ADMIN`, `STAFF` | Lista suscripciones paginadas, permitiendo filtrar por socio (`member_number`) o estado de vigencia. | Query params: `page`, `size`, `member_number`, `active` | `200 OK`. |
| **RF-12** | `GET` | `/api/subscriptions/{id}` | `ADMIN`, `STAFF` | Recupera la información detallada de una suscripción específica por su identificador (`subscription_number`). | Path param: `id` (Integer) | `200 OK`, `404 Not Found`. |
| **RF-13** | `POST` | `/api/subscriptions` | `ADMIN`, `STAFF` | Da de alta una nueva suscripción para un socio activo, vinculando el plan elegido (`plan_code`) y fecha de inicio (`start_date`). La fecha de fin (`end_date`) se calcula determinísticamente en el backend sumando exactamente un mes calendario (`plusMonths(1)`) con fin exclusivo `[)` y preservando el día ancla derivado de la cadena contigua para evitar derivas de fin de mes, por lo que el cliente no la envía. El precio base se toma obligatoriamente de `plans.current_price`; el cliente no puede enviar ni establecer el precio. Se congelan el precio y descuento aplicados. | `{"member_number": "1001", "plan_code": "THREE_DAYS", "discount": 0.00, "start_date": "2026-10-05T18:00:00-03:00"}` | `201 Created`, `400 Bad Request` (fecha de inicio inválida, descuento inválido, plan o socio inexistente/inactivo), `409 Conflict` (se superpone con otra suscripción del socio). |
| **RF-14** | `PUT` | `/api/subscriptions/{id}` | `ADMIN`, `STAFF` | Modifica exclusivamente los comentarios (`comments`) de la suscripción. Ningún otro campo puede modificarse. | Path param: `id`. Body: `{"comments": "..."}` | `200 OK`, `400 Bad Request` (campo distinto de `comments`), `404 Not Found`. |
| **RF-15** | `DELETE` | `/api/subscriptions/{id}` | `ADMIN` | Realiza la baja lógica de la suscripción (actualiza `status = 'CANCELLED'`), denegando inmediatamente el acceso en terminal de acceso. Preserva inmutables los pagos acreditados (`PAID`) sin reintegros automáticos y mantiene el historial de accesos. | Path param: `id` | `204 No Content`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Historial, Vigencia y No Solapamiento:** Un socio puede poseer múltiples suscripciones a lo largo del tiempo que componen su historial contractual. Cada período mensual abarca un mes calendario con fin estrictamente exclusivo (`[)`), preservando el día ancla original deducido de la cadena contigua de suscripciones no canceladas para evitar derivas acumulativas en meses de distinta duración (por ejemplo, del 31 de enero al 28 de febrero y de allí al 31 de marzo). En el instante exacto de finalización el acceso queda caducado. No pueden existir dos períodos de suscripción activos superpuestos para un mismo socio.
2. **Cupo Semanal:** El límite semanal corresponde al plan contratado; el consumo se determina computando los días distintos con acceso concedido dentro de la semana operativa local, sin que los reingresos durante la misma jornada impliquen consumo adicional. No se mantiene un contador persistido de asistencias.
3. **Congelamiento de Condiciones Comerciales:** El precio pactado y el descuento otorgado se congelan al dar de alta la suscripción como fotografía histórica de las condiciones vigentes. Futuras variaciones en el catálogo de tarifas no afectan a los contratos ya emitidos.
4. **Baja Lógica, Denegación de Acceso e Inmutabilidad de Pagos (AC5):** La cancelación de una suscripción inhabilita de inmediato el acceso al gimnasio por carecer de cobertura activa. Los comprobantes de cobro acreditados previamente como pagados permanecen inmutables para resguardo de la auditoría y del arqueo de caja, sin cancelaciones ni reintegros automáticos. La cancelación libera la cobertura temporal para posibilitar una nueva contratación sin solapamientos.
5. **Inmutabilidad del Plan Contratado y Regla de Renovación (AC6):** La modalidad de una suscripción vigente no puede alterarse durante el período pactado. Todo cambio de plan solicitado por el socio debe formalizarse como una nueva contratación para el período siguiente que inicie al concluir el término actual.

**Notas Técnicas del Contrato:**
- El cálculo del término `end_date` en `RF-13` es ejecutado exclusivamente en el backend sumando determinísticamente un mes calendario sobre instantes con zona horaria mediante `plusMonths(1)`, aplicando fin semiabierto `[)` y respetando el día ancla de la cadena continua previa. El cliente no envía ni edita este campo.
- La garantía contra solapamientos de fechas entre suscripciones activas del mismo socio reside a nivel de motor de datos en la restricción de exclusión `no_overlap_subscriptions` (`EXCLUDE USING gist` sobre `member_number` y `tstzrange` con predicado `WHERE (status != 'CANCELLED')`). Fundamentado en [ADR-0007](./adr/ADR-0007-prevencion-solapamiento-suscripciones-restriccion-gist.md).
- El snapshot de precios y la congelación contractual de condiciones tarifarias se fundamentan en [ADR-0006](./adr/ADR-0006-catalogo-tarifario-inmutabilidad-snapshot-precios.md).
- La conservación de registros históricos de pago y auditoría ante la cancelación de suscripciones se asegura mediante restricciones `ON DELETE RESTRICT` y el patrón de baja lógica, conforme a [ADR-0005](./adr/ADR-0005-conservacion-historial-integridad-declarativa.md).
---

### 1.4. Módulo Payment (`PaymentController`, `PaymentService`)

- **Objetivos:** Registrar y supervisar los pagos efectuados por los socios para saldar sus suscripciones. Soporta múltiples transacciones por suscripción (abonos parciales o renovaciones), distintos métodos de pago y estados transaccionales (`PENDING`, `PAID`, `FAILED`, `CANCELLED`), preparando la arquitectura para la integración de pasarelas como Mercado Pago.
- **Entidades involucradas:** `Payment` (`payments`), `Subscription` (`subscriptions`), `Employee` (`employees`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-16** | `GET` | `/api/payments` | `ADMIN`, `STAFF` | Consulta listado de pagos registrados con paginación y filtros por suscripción (`subscription_number`), cajero (`employee_code`), estado o rango de fechas de registro (`created_at`). Con `employee_code`, `from` y `to` se arma el cierre de caja de un turno. | Query params: `page`, `size`, `subscription_number`, `employee_code`, `status`, `from`, `to` | `200 OK`. |
| **RF-17** | `GET` | `/api/payments/{id}` | `ADMIN`, `STAFF` | Obtiene los datos detallados de un comprobante de pago por su número de recibo (`receipt_number`). | Path param: `id` (Integer) | `200 OK`, `404 Not Found`. |
| **RF-18** | `POST` | `/api/payments` | `ADMIN`, `STAFF` | Registra un nuevo cobro en caja asociado a una suscripción. El empleado que cobra (`employee_code`) se toma del usuario logueado al crear el cobro; no se envía en el body. El estado no lo manda el cliente: un cobro en efectivo (`CASH`) nace `PAID` y uno con el QR de Mercado Pago nace `PENDING` hasta que llega la confirmación (RF-19). | `{"subscription_number": 1520, "amount": 25000.00, "payment_method": "CASH"}` | `201 Created`, `400 Bad Request` (monto inválido `<= 0` o método de pago que no sea `CASH` ni `MERCADO_PAGO`), `404 Not Found` (suscripción inexistente), `409 Conflict` (el monto supera el saldo pendiente). |
| **RF-19** | `PUT` | `/api/payments/{id}` | Mercado Pago (confirmación), `ADMIN` (anulación) | Actualiza el estado de una transacción o referencia externa (ej. confirmación de webhook de pago): pasa un pago `PENDING` a `PAID` o `FAILED` y guarda el `gateway_payment_id`. `ADMIN` también lo usa para pasar un pago a `CANCELLED` ante un error de carga (regla 2). No lee ni modifica el `employee_code`, que quedó fijado al crear el cobro. | Path param: `id`. Body con nuevo estado o datos de conciliación. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Contractual:** Todo comprobante de cobro debe asociarse obligatoriamente a una suscripción existente; no se admiten cobros huérfanos.
2. **Inmutabilidad Financiera y Anulación Operativa (AC5):** Los cobros registrados en condición de pagados (`PAID`) son financieramente inmutables. La cancelación de la suscripción asociada no altera los cobros pagados, protegiendo la recaudación y el arqueo de caja. Ante un error operativo directo de imputación en mostrador, el comprobante se anula pasando a estado `CANCELLED` para preservar la auditoría sin supresión física.
3. **Validación de Montos:** Todo cobro debe registrar un importe estrictamente positivo. Los cobros no admiten descuentos directos; el único descuento aplicable es el pactado en la suscripción, que reduce el saldo exigible.
4. **Límite de Cobro sobre Saldo Pendiente:** El saldo exigible de una suscripción corresponde a $(\text{price} - \text{discount}) - \sum \text{amount}_{\text{PAID}}$. No se admiten cobros por un importe superior a dicho saldo pendiente ni nuevos cobros sobre contratos saldados.
5. **Responsabilidad del Cajero:** Todo cobro presencial en mostrador queda imputado de forma definitiva al empleado que atiende la caja para el cierre y balance de su turno, incluso cuando el socio abona mediante código QR. La autoría del cobro se fija al iniciar la operación y no se modifica ante confirmaciones posteriores o cambios de turno. Solo los pagos digitales realizados directamente por el socio sin intervención presencial pueden carecer de empleado asociado.

**Notas Técnicas del Contrato:**
- La comprobación del saldo disponible y el registro del cobro en `RF-18` se ejecutan dentro de una transacción aislada con bloqueo pesimista sobre la suscripción (`SELECT ... FOR UPDATE`), garantizando que solicitudes concurrentes no excedan el saldo pendiente ni generen cobros duplicados. En el frontend, la interfaz deshabilita el control de envío durante el tránsito de la petición. Esta concurrencia crítica está contemplada en [ADR-0008](./adr/ADR-0008-modelo-pagos-ledger-inmutable-estrategia-metodo.md) y en la decisión proyectada `ADR-0015` del catálogo de arquitectura.
- La restricción de base de datos `chk_payment_employee` exige `employee_code` en todo cobro presencial, permitiendo su ausencia únicamente cuando el medio de pago registrado es `MERCADO_PAGO` originado fuera de mostrador.
- La inmutabilidad de los cobros acreditados y la persistencia de comprobantes anulados para auditoría se respaldan en [ADR-0005](./adr/ADR-0005-conservacion-historial-integridad-declarativa.md) y [ADR-0008](./adr/ADR-0008-modelo-pagos-ledger-inmutable-estrategia-metodo.md).
---

### 1.5. Módulo Access (`AccessController`, `AccessService`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría de cada intento de acceso.
- **Criterio de diseño:** Dado que cada acceso constituye un evento de auditoría en una serie temporal (identificado por el número correlativo `access_id`), **no se exponen operaciones CRUD planas** (`PUT` o `DELETE`). Los registros de acceso son inmutables y no se editan ni eliminan manualmente.
- **Entidades involucradas:** `Access` (`access_logs`), `Member` (`members`), `Subscription` (`subscriptions`), `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-20** | `POST` | `/api/access/validate` | `STAFF` (sesión abierta en la terminal) | **Operación central de negocio.** Recibe la identificación del socio (`member_number`), evalúa en tiempo real la existencia y activación del socio, la cuota al día, la vigencia temporal de la suscripción (momento actual dentro de `[start_date, end_date)`) y el cupo semanal del Plan; persiste el intento en `access_logs`. La vigencia y la deuda se calculan en cada validación, sin mutar estados por vencimiento o mora. El uso semanal se obtiene contando los días distintos con ingreso concedido desde el lunes (hora de Argentina) y el límite proviene de `plans.weekly_limit`. | `{"member_number": "1001"}` | `200 OK` (`GRANTED` o `DENIED`, ver Respuesta de la terminal), `400 Bad Request` (número vacío). |
| **RF-21** | `GET` | `/api/access` | `ADMIN`, `STAFF` | Consulta el registro histórico de accesos para reportes, auditoría y análisis de afluencia. Permite filtrar por rango de fechas, socio (`member_number`) y resultado (`GRANTED` / `DENIED`). | Query params: `page`, `size`, `member_number`, `status`, `from`, `to` | `200 OK` (listado paginado). |

**Respuesta de la terminal (RF-20):** siempre `200 OK`, con estos campos:

- `status`: `GRANTED` o `DENIED`.
- `denied_reason`: el motivo del rechazo (enum `DeniedReason`); vacío si se concede.
- `member_name`: nombre y apellido del socio; vacío con `MEMBER_NOT_FOUND`, porque no hay socio.
- `plan_name`: el plan de la suscripción vigente; solo si se concede.
- `remaining_days`: días que le quedan en la semana, contando el de hoy; solo si se concede y vacío si el plan es pase libre (`weekly_limit` vacío).

Ana tiene 3 días por semana y entra el martes por segunda vez en la semana:

```json
{"status": "GRANTED", "denied_reason": null, "member_name": "Ana Pérez", "plan_name": "3 días por semana", "remaining_days": 1}
```

Si vuelve el martes a la tarde, la respuesta es la misma, porque ese día ya estaba contado. Si debe la cuota:

```json
{"status": "DENIED", "denied_reason": "PAYMENT_OVERDUE", "member_name": "Ana Pérez", "plan_name": null, "remaining_days": null}
```

El backend manda el motivo y la terminal muestra el texto (ver Módulo Validación Visual).

**Reglas de Negocio Formales:**
1. **Precedencia del Motor de Decisión:** La validación de acceso evalúa las condiciones del socio en orden secuencial estricto, deteniéndose ante la primera condición insatisfecha:
   1. Identificación no registrada: Si el número ingresado no corresponde a ningún socio, el acceso es denegado por motivo `MEMBER_NOT_FOUND`.
   2. Socio inactivo: Si el socio está suspendido o dado de baja administrativa, el acceso es denegado por motivo `MEMBER_INACTIVE`.
   3. Ausencia de contrato vigente: Si no existe una suscripción activa cuya vigencia temporal comprenda el momento actual, el acceso es denegado por motivo `NO_ACTIVE_SUBSCRIPTION`.
   4. Cuota impaga: Si existe suscripción vigente pero los cobros pagados no cubren el importe pactado, el acceso es denegado por motivo `PAYMENT_OVERDUE`.
   5. Cupo semanal agotado: Si se alcanzó el límite de asistencias semanales del plan contratado, el acceso es denegado por motivo `WEEKLY_LIMIT_REACHED`.
   6. Habilitación: Si se satisfacen todas las condiciones previas, el acceso es concedido (`GRANTED`).

   **Tolerancia de Reingreso Intradía:** El cómputo de cupo semanal contabiliza días calendario distintos de asistencia. Si el socio ya registró un ingreso concedido durante la jornada, los reingresos posteriores en el mismo día no consumen asistencias adicionales, permitiendo el acceso si mantiene las condiciones de cuota y vigencia al día.
2. **Inmutabilidad y Cobertura de Auditoría:** Todo intento de ingreso, tanto concedido como denegado (incluso cuando el número digitado no pertenece a un socio registrado), constituye un evento de auditoría histórico inalterable. La verificación de vigencia y deuda se computa dinámicamente en cada presentación sin mutar estados ni registrar vencimientos automáticos.
3. **Determinación de Cuota al Día y Membresías Bonificadas (AC4):** La condición de cuota al día exige que el acumulado de cobros efectivamente acreditados (`PAID`) alcance o supere el importe neto pactado en la suscripción vigente: $\sum \text{amount}_{\text{PAID}} \ge (\text{price} - \text{discount})$. Cuando el importe neto es $0.00 (planes gratuitos o bonificaciones totales), la condición se satisface sin requerir registro de pagos.

**Notas Técnicas del Contrato:**
- El endpoint `POST /api/access/validate` (`RF-20`) responde invariablemente `200 OK` transportando el resultado semántico (`status: GRANTED` o `DENIED`), el motivo formal (`denied_reason`) y los datos complementarios para su señalización visual en pantalla.
- La persistencia de auditoría se ejecuta registrando en `access_logs` el valor literal ingresado (`entered_member_number`), la marca de tiempo del servidor y las referencias foráneas opcionales (`member_number` nulo ante `MEMBER_NOT_FOUND`, y `subscription_number` asociado en autorizaciones o rechazos por cuota/cupo según restricciones `chk_access_logic` y `chk_access_not_found`).
- La arquitectura secuencial de validación desacoplada se formaliza mediante el patrón *Chain of Responsibility* en [ADR-0011](./adr/ADR-0011-patron-chain-of-responsibility-validacion-accesos.md).
- La conservación de eventos inmutables de acceso y el cálculo de estado derivado sin contadores persistidos se fundamentan en [ADR-0005](./adr/ADR-0005-conservacion-historial-integridad-declarativa.md), [ADR-0009](./adr/ADR-0009-auditoria-forense-terminal-acceso-estado-derivado.md) y [ADR-0010](./adr/ADR-0010-tratamiento-temporal-universal-timestamptz-clock.md).
---

### 1.6. Módulo Plans (`PlanController`, `PlanService`)

- **Objetivos:** Administrar el catálogo dinámico `plans`, identificado mediante `plan_code`, con cupos semanales, precios de lista (`current_price`) y estado activo, proveyendo el soporte de backend documentado para la Pantalla 5 de los mockups.
- **Entidades involucradas:** `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-22** | `GET` | `/api/plans` | `ADMIN`, `STAFF` | Recupera los registros activos del catálogo `plans`, con sus datos vigentes. | Ninguno | `200 OK`. |
| **RF-23** | `GET` | `/api/plans/{plan_code}` | `ADMIN`, `STAFF` | Obtiene los detalles de un plan por su código natural (`plan_code`). | Path param: `plan_code` | `200 OK`, `404 Not Found`. |
| **RF-24** | `POST` | `/api/plans` | `ADMIN` | Crea un registro Plan en el catálogo. | `{"plan_code": "WEEKEND", "name": "Pase Fines de Semana", "weekly_limit": 2, "current_price": 12000.00}` | `201 Created`, `400 Bad Request` (código vacío o duplicado, arancel negativo). |
| **RF-25** | `PUT` | `/api/plans/{plan_code}` | `ADMIN` | Actualiza arancel vigente (`current_price`), cupo semanal o estado de activación de un plan. | Path param: `plan_code`. Body con nuevos valores. | `200 OK`, `400 Bad Request`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Inmutabilidad de Contratos Previos:** Modificar el precio de lista (`current_price`) de un plan no altera bajo ningún concepto las suscripciones ya emitidas (`subscriptions.price` congelado al momento del alta).
2. **Conservación Referencial:** Un plan con suscripciones históricas no puede ser borrado físicamente de la base de datos (`ON DELETE RESTRICT`). Las bajas se gestionan de forma lógica mediante el atributo `active = false`.

---

### 1.7. Módulo Reports (`ReportController`, `ReportService`)

- **Objetivos:** Dar al dashboard y a los reportes los datos que calculan a partir de socios, suscripciones, pagos y accesos: afluencia, horarios pico, recaudación por plan y asistencia de cada socio.
- **Entidades involucradas:** `Member` (`members`), `Subscription` (`subscriptions`), `Plan` (`plans`), `Payment` (`payments`), `Access` (`access_logs`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-26** | `GET` | `/api/reports/summary` | `ADMIN`, `STAFF` | Resumen del dashboard: socios activos al día, accesos concedidos hoy, socios con la cuota vencida, suscripciones que vencen en los próximos 7 días, recaudación del mes y monto pendiente de cobro. `STAFF` lo recibe sin los dos montos. | Ninguno | `200 OK`. |
| **RF-27** | `GET` | `/api/reports/access-by-hour` | `ADMIN`, `STAFF` | Cantidad de accesos concedidos por hora del día en un rango de fechas, para ver los horarios pico. | Query params: `from`, `to` | `200 OK`, `400 Bad Request` (rango inválido). |
| **RF-28** | `GET` | `/api/reports/members-by-plan` | `ADMIN`, `STAFF` | Cantidad de socios con suscripción vigente en cada plan. | Ninguno | `200 OK`. |
| **RF-29** | `GET` | `/api/reports/income` | `ADMIN` | Recaudación por plan en un período: suma de los pagos `PAID` de las suscripciones de cada plan. | Query params: `from`, `to` | `200 OK`, `400 Bad Request` (rango inválido). |
| **RF-30** | `GET` | `/api/reports/attendance` | `ADMIN`, `STAFF` | Asistencia mensual de un socio: los días del mes en que tuvo un acceso concedido. | Query params: `member_number`, `month` (ej. `2026-10`) | `200 OK`, `400 Bad Request`, `404 Not Found` (socio inexistente). |

**Reglas de Negocio Formales:**
1. **Solo lectura y calculado:** Los reportes se calculan con consultas sobre los datos guardados. No se guardan totales ni contadores, para que no queden distintos de los datos de origen.
2. **Hora de Argentina:** Los días, las horas y los meses se cuentan en hora de Argentina, igual que el cupo semanal.
3. **Recaudación:** Solo cuentan los pagos `PAID`, por su fecha de registro (`created_at`), como en el cierre de caja (RF-16). Un socio está al día con el mismo criterio de la regla 3 del Módulo Access.
4. **Montos solo para `ADMIN`:** `STAFF` ve la parte operativa del dashboard (socios, accesos y vencimientos) pero no la recaudación ni los montos pendientes.

---

### 1.8. Módulo Communications (`CommunicationController`, `CommunicationService`)

- **Objetivos:** Enviar por email los comunicados del gimnasio a los socios y el aviso automático antes de que venza una suscripción.
- **Entidades involucradas:** `Member` (`members`), `Person` (`persons`), `Subscription` (`subscriptions`), `Payment` (`payments`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-31** | `POST` | `/api/communications/broadcast` | `ADMIN` | Envía un comunicado por email a todos los socios, solo a los activos o solo a los que tienen la cuota vencida. Por ejemplo, "El lunes feriado el gimnasio abre de 9 a 13". | `{"audience": "ACTIVE", "subject": "...", "body": "..."}` (`audience`: `ALL`, `ACTIVE` u `OVERDUE`) | `200 OK` (cantidad de emails enviados), `400 Bad Request` (destinatarios inválidos, asunto o cuerpo vacío). |
| **RF-32** | — | *Tarea programada diaria* | Sistema | Avisa por email al socio 3 días antes de que venza su suscripción, para que renueve. No tiene endpoint: el backend la ejecuta una vez por día. | — | — |

**Reglas de Negocio Formales:**
1. **Solo email en V1:** Los mensajes se envían al email de contacto de la persona (`persons.email`). Un socio que solo dejó teléfono no los recibe. WhatsApp queda fuera de alcance (ver README).
2. **Un email por familia:** Si varios socios comparten el mismo email (por ejemplo, dos hermanos menores con el email de su madre), el comunicado se envía una sola vez a esa dirección.
3. **Destinatarios:** `ACTIVE` son los socios con `members.status = 'ACTIVE'`. `OVERDUE` son los que tienen una suscripción vigente sin cubrir el saldo, con el mismo criterio de la regla 3 del Módulo Access.
4. **Aviso de vencimiento:** Se avisa por cada suscripción no cancelada que vence justo dentro de 3 días, en hora de Argentina (por ejemplo, la tarea del lunes avisa a las suscripciones que vencen el jueves). Si el socio ya tiene cargada la suscripción siguiente, no se le avisa. Como la tarea corre una vez por día y elige un solo día de vencimiento, cada suscripción recibe un único aviso.

## 2. Módulos de Frontend Panel Administrativo (`gym-frontend-admin`)

### 2.1. Módulo Dashboard (RF-33)
- **Objetivos:** Proveer al administrador y personal autorizado una vista integral y ejecutiva del estado operativo del gimnasio.
- **Funcionalidades documentadas:** consume RF-26 a RF-28 del Módulo Reports y, para el feed de accesos en tiempo real, RF-21.
  - Métricas de afluencia diaria y semanal en base al módulo Access.
  - Horarios pico y distribución de visitas según el Plan contratado, mediante `subscriptions.plan_code` y datos de `plans`.
  - Resumen financiero de ingresos mensuales y cobros pendientes del módulo Payment.
  - Total de socios activos y alertas de suscripciones próximas a vencer.
  - Modal de comunicaciones (solo `ADMIN`): comunicado masivo con RF-31 y la plantilla del aviso automático de RF-32.
- Estas funcionalidades son requisitos de diseño, no evidencia de que la pantalla o sus endpoints estén implementados.

### 2.2. Módulo ABM (Gestión Administrativa) (RF-34)
- **Objetivos:** Centralizar las operaciones de administración del sistema mediante interfaces responsivas y securizadas por JWT.
- **Funcionalidades documentadas:**
  - **Gestión de Socios y Personal:** Altas, modificaciones, visualización de fichas individuales y gestión de estados consumiendo `/api/members` y `/api/employees`.
  - **Gestión de Suscripciones:** Asignación de planes mediante `plan_code`, prórrogas y monitoreo de vigencia consumiendo los contratos `/api/subscriptions`.
  - **Gestión de Cobros:** Registro manual de pagos, emisión de comprobantes internos y seguimiento de estados transaccionales consumiendo `/api/payments`.
  - **Monitor de Accesos:** Vista y reportes históricos de ingresos y rechazos consumiendo `/api/access`.
  - **Configuración Tarifaria y Planes (Pantalla 5 de mockups):** Administración dinámica de Plan (`plan_code`, `weekly_limit`, `current_price`, `active`) mediante los contratos `/api/plans`.
- Las capacidades listadas son contratos documentados; su aparición aquí no implica que las pantallas, controladores o endpoints correspondientes estén implementados.

---

## 3. Módulos de Frontend Terminal de Acceso (`gym-access-terminal`)

### 3.1. Módulo Validación Visual (RF-35)
- **Objetivos:** Ofrecer una interfaz minimalista, autónoma y de respuesta instantánea para la terminal ubicada en el acceso físico del gimnasio.
- **Funcionalidades:**
  - Interfaz de entrada para ingresar el número de socio (`member_number`) mediante teclado numérico o lector de credenciales (preservando el DNI como dato administrativo por privacidad).
  - Consumo del endpoint de negocio `POST /api/access/validate`.
  - **GRANTED (Aprobado):** mensaje de bienvenida con el nombre del socio (`member_name`), plan vigente (`plan_name`) y días que le quedan en la semana (`remaining_days`; en pase libre no se muestra).
  - **DENIED (Rechazado):** un mensaje por cada `denied_reason`: "Número de socio no encontrado" (`MEMBER_NOT_FOUND`), "Socio dado de baja" (`MEMBER_INACTIVE`), "Sin suscripción vigente" (`NO_ACTIVE_SUBSCRIPTION`), "Cuota impaga" (`PAYMENT_OVERDUE`) o "Ya usaste los días de esta semana" (`WEEKLY_LIMIT_REACHED`), pidiendo que se acerque a recepción.

---

## 4. Matriz de Trazabilidad Global

Esta matriz vincula de forma directa los Requerimientos Funcionales (RF) detallados en el sistema con sus respectivos Endpoints de resolución técnica y las reglas de negocio que deben cumplir para garantizar la solidez de la arquitectura.

| Código | Requerimiento Funcional | Endpoint / Módulo de Resolución | Regla de Negocio / Criterio de Aceptación Restrictivo |
|---|---|---|---|
| **RF-01** | Autenticación y generación de sesión | `POST /api/auth/login` | Solo para `ADMIN` o `STAFF` con cuenta activa. Valida `work_email` y `password`. Genera JWT inmutable. |
| **RF-02** | Consulta general de socios | `GET /api/members` | `ADMIN` y `STAFF`. Soporta paginación y filtros de estado. |
| **RF-03** | Consulta individual de perfil de socio | `GET /api/members/{member_number}` | Búsqueda por número de socio (clave natural de negocio). |
| **RF-04** | Registro de nuevos socios | `POST /api/members` | DNI protegido operativamente. Email o teléfono obligatorios. |
| **RF-05** | Modificación de datos de socios | `PUT /api/members/{member_number}` | Clave natural `member_number` inmutable. |
| **RF-06** | Baja/Alta lógica de socios | `POST /api/members/{member_number}/status` | Actualiza estado (`ACTIVE` / `INACTIVE`) sin borrar historial inmutable. |
| **RF-07** | Listado de empleados | `GET /api/employees` | Exclusivo `ADMIN`. Paginación y filtro por rol. |
| **RF-08** | Alta de empleados | `POST /api/employees` | Exclusivo `ADMIN`. `employee_code` y `work_email` únicos; si el DNI ya existe, se suma el rol a esa persona. |
| **RF-09** | Modificación de datos de empleados | `PUT /api/employees/{employee_code}` | Exclusivo `ADMIN`. `employee_code` inmutable; `work_email` sigue siendo único. |
| **RF-10** | Activación/desactivación de empleados | `POST /api/employees/{employee_code}/status` | Exclusivo `ADMIN`. Baja lógica (`active = false`): no puede iniciar sesión y sus cobros siguen a su nombre. |
| **RF-11** | Listado histórico de suscripciones | `GET /api/subscriptions` | Soporta filtros de vigencia. |
| **RF-12** | Consulta de detalle de suscripción | `GET /api/subscriptions/{id}` | - |
| **RF-13** | Alta de suscripción | `POST /api/subscriptions` | Prohibido solapar fechas de vigencia para un mismo socio. El backend calcula `end_date` sumando un mes a `start_date`. El precio base se toma obligatoriamente de `plans.current_price` y se congela junto con el descuento aplicado. |
| **RF-14** | Modificación de comentarios de suscripción | `PUT /api/subscriptions/{id}` | Solo permite modificar `comments`; ningún otro campo es modificable. |
| **RF-15** | Cancelación lógica de suscripción | `DELETE /api/subscriptions/{id}` | Baja lógica (`status = 'CANCELLED'`) que deniega acceso inmediato, preserva inmutables los pagos `PAID` (sin reintegro automático) y libera el rango temporal de solapamiento. |
| **RF-16** | Auditoría y lista general de pagos | `GET /api/payments` | Filtra por cajero y rango de fechas para el cierre de caja. |
| **RF-17** | Consulta de comprobante específico | `GET /api/payments/{id}` | - |
| **RF-18** | Registro de abonos y comprobantes | `POST /api/payments` | No admite transacciones huérfanas sin referenciar a `subscription_number`. Valida `amount > 0` y rechaza con `409` el monto que supere el saldo pendiente. Guarda el cajero logueado. |
| **RF-19** | Conciliación transaccional (Webhooks) | `PUT /api/payments/{id}` | Registros `PAID` son financieramente inmutables (se marcan `CANCELLED` ante error). |
| **RF-20** | Validación de ingreso en terminal | `POST /api/access/validate` | Evalúa en orden: número inexistente, socio de baja, sin suscripción vigente, cuota impaga ($\sum \text{amount}_{\text{PAID}} < \text{price} - \text{discount}$) y cupo semanal. Responde `200 OK` con el motivo. |
| **RF-21** | Historial de auditoría de ingresos | `GET /api/access` | Estrictamente lectura. Operaciones CRUD (`PUT`/`DELETE`) inhabilitadas. |
| **RF-22** | Catálogo general de planes | `GET /api/plans` | Lista registros del catálogo `plans` con sus datos. |
| **RF-23** | Consulta de plan por código | `GET /api/plans/{plan_code}` | Consulta por clave natural `plan_code`. |
| **RF-24** | Creación de nuevos planes | `POST /api/plans` | Exclusivo `ADMIN`. Valida código único y restricciones documentadas de datos. |
| **RF-25** | Modificación de datos de planes | `PUT /api/plans/{plan_code}` | Actualiza datos del catálogo; los cambios de precio no alteran los snapshots históricos en `subscriptions.price`. |
| **RF-26** | Resumen del dashboard | `GET /api/reports/summary` | Calculado, sin totales guardados. `STAFF` lo recibe sin montos. |
| **RF-27** | Accesos por hora | `GET /api/reports/access-by-hour` | Cuenta accesos `GRANTED` por hora, en hora de Argentina. |
| **RF-28** | Socios por plan | `GET /api/reports/members-by-plan` | Cuenta socios con suscripción vigente en cada plan. |
| **RF-29** | Recaudación por plan y período | `GET /api/reports/income` | Exclusivo `ADMIN`. Solo pagos `PAID`, por fecha de registro. |
| **RF-30** | Asistencia mensual por socio | `GET /api/reports/attendance` | Días distintos con acceso `GRANTED` en el mes. |
| **RF-31** | Comunicado masivo por email | `POST /api/communications/broadcast` | Exclusivo `ADMIN`. Destinatarios: todos, activos o con cuota vencida; un solo envío por email compartido. |
| **RF-32** | Aviso automático de vencimiento | *Tarea programada diaria* | Un aviso por suscripción, 3 días antes de `end_date`, salvo que ya esté cargada la siguiente. |
| **RF-33** | Visualización métricas financieras | *Frontend / Dashboard* | Consolida cálculos cruzados de Accesos y Pagos. |
| **RF-34** | Interfaces de Gestión Administrativa | *Frontend / Panel ABM* | Consumo de toda la API protegido vía Bearer Token JWT. |
| **RF-35** | Control de puerta y validación visual | *Frontend / Terminal* | Proporciona feedback semántico en tiempo real (Verde/Rojo). |
