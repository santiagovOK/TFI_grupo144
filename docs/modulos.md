# Especificación de Módulos del Sistema y Contratos de Interfaz

Este documento define la arquitectura modular del sistema **Gym Manager**, detallando para cada componente sus objetivos específicos, las entidades del modelo de datos involucradas, los Requerimientos Funcionales (RF) y los contratos formalizados de interfaz REST.

---

**Estado de implementación:** este documento especifica contratos y comportamientos objetivo; su inclusión aquí no afirma que los endpoints, controladores o pantallas estén implementados.

**Roles:** `ADMIN` es el encargado o dueño del gimnasio y `STAFF` es recepción. Cada contrato indica qué roles pueden usarlo; si lo llama un usuario con otro rol, la respuesta es `403 Forbidden`.

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`AuthController`, `AuthService`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `Employee` (`employees`), `Person` (`persons`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-01** | `POST` | `/api/auth/login` | Sin token | Autentica credenciales de usuario (email de trabajo `work_email` y contraseña) y devuelve un token Bearer JWT con los roles asignados. | `{"work_email": "admin@gym.com", "password": "..."}` | `200 OK` (token JWT y datos de sesión), `401 Unauthorized` (credenciales inválidas), `403 Forbidden` (usuario inactivo). |

**Reglas de Negocio Formales:**
1. Solo los usuarios con rol `ADMIN` o `STAFF` y con estado `active = true` están autorizados para autenticarse y recibir un token JWT.
2. Los tokens JWT emitidos son inmutables; cualquier alteración de roles o permisos requerirá un nuevo inicio de sesión.
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
| **RF-13** | `POST` | `/api/subscriptions` | `ADMIN`, `STAFF` | Da de alta una nueva suscripción para un socio activo, vinculando el plan elegido (`plan_code`) y fecha de inicio (`start_date`). La fecha de fin (`end_date`) se calcula determinísticamente en el backend sumando exactamente un mes calendario (`plusMonths(1)`), por lo que el cliente no la envía. El precio base se toma obligatoriamente de `plans.current_price`; el cliente no puede enviar ni establecer el precio. Se congelan el precio y descuento aplicados. | `{"member_number": "1001", "plan_code": "THREE_DAYS", "discount": 0.00, "start_date": "2026-10-05T18:00:00-03:00"}` | `201 Created`, `400 Bad Request` (fecha de inicio inválida, descuento inválido, plan o socio inexistente/inactivo), `409 Conflict` (se superpone con otra suscripción del socio). |
| **RF-14** | `PUT` | `/api/subscriptions/{id}` | `ADMIN`, `STAFF` | Modifica exclusivamente los comentarios (`comments`) de la suscripción. Ningún otro campo puede modificarse. | Path param: `id`. Body: `{"comments": "..."}` | `200 OK`, `400 Bad Request` (campo distinto de `comments`), `404 Not Found`. |
| **RF-15** | `DELETE` | `/api/subscriptions/{id}` | `ADMIN` | Realiza la baja lógica de la suscripción (actualiza `status = 'CANCELLED'`), denegando inmediatamente el acceso en terminal de acceso. Preserva inmutables los pagos acreditados (`PAID`) sin reintegros automáticos y mantiene el historial de accesos. | Path param: `id` | `204 No Content`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Historial, Vigencia y No Solapamiento:** Un socio puede poseer múltiples registros de suscripción (1:N) a modo de historial. El período mensual de cada suscripción se calcula estrictamente en el backend sumando un mes calendario a `start_date` con fin exclusivo (`[)`), impidiendo que el cliente fije una duración arbitraria (`end_date` no es modificable ni enviado en el alta). El motor de base de datos prohíbe que existan dos suscripciones activas con fechas superpuestas mediante una restricción de exclusión (`no_overlap_subscriptions` con `EXCLUDE USING gist`), evaluada exclusivamente sobre registros con `status != 'CANCELLED'`.
2. **Cupo Semanal:** el límite se consulta en el plan asociado (`plans.weekly_limit`) y el uso se calcula contando los días distintos con ingreso concedido (`GRANTED`) desde el lunes a las 00:00 de la semana en curso, en hora de Argentina; los reingresos del mismo día no descuentan. La restricción de base de datos requiere un valor no negativo cuando el límite está informado. No se almacena un contador.
3. **Congelamiento de Condiciones Comerciales:** `subscriptions.price` conserva un snapshot histórico del `plans.current_price` aplicado al crear la suscripción, junto con el descuento concedido (`discount`). Los cambios posteriores en el catálogo no alteran los valores históricos del registro.
4. **Baja Lógica, Denegación de Acceso e Inmutabilidad de Pagos (AC5):** La cancelación de una suscripción (`DELETE /api/subscriptions/{id}`, RF-15) opera como una baja lógica actualizando su estado a `CANCELLED`. Esta acción produce los siguientes efectos inmediatos: (a) el acceso en terminal de acceso es denegado de forma instantánea (`DENIED`) por carecer de suscripción vigente; (b) los comprobantes de cobro vinculados en `payments` que ya tengan estado `PAID` permanecen inmutables como `PAID` para auditoría y arqueo de caja (no transicionan a `CANCELLED` ni se generan notas de crédito o reintegros automáticos; cualquier compensación monetaria es un procedimiento manual fuera del sistema); y (c) se respeta la integridad referencial (`ON DELETE RESTRICT`), liberando de inmediato el rango temporal de solapamiento (`no_overlap_subscriptions`) para permitir el alta de un nuevo período sin conflictos.
5. **Inmutabilidad del Plan Contratado y Regla de Renovación (AC6):** El campo `plan_code` de una suscripción vigente es estrictamente inmutable a través de `PUT /api/subscriptions/{id}`. Todo cambio de modalidad solicitado por el socio debe respetar el período actual intacto bajo su tarifa histórica pactada, debiendo registrarse el cambio mediante la creación de una nueva suscripción para el período siguiente (`POST /api/subscriptions`), cuyo `start_date` coincida con el vencimiento actual, aprovechando que el motor de base de datos permite encolar períodos futuros sin solapamiento. No se admiten cálculos de créditos o días proporcionales a mitad de período en V1.
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
| **RF-19** | `PUT` | `/api/payments/{id}` | Mercado Pago (sin usuario) | Actualiza el estado de una transacción o referencia externa (ej. confirmación de webhook de pago): pasa un pago `PENDING` a `PAID` o `FAILED` y guarda el `gateway_payment_id`. No lee ni modifica el `employee_code`, que quedó fijado al crear el cobro. | Path param: `id`. Body con nuevo estado o datos de conciliación. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Transaccional:** Todo registro de cobro debe referenciar de forma obligatoria a una suscripción existente (`subscription_number`); no se admiten pagos "huérfanos".
2. **Idempotencia e Inmutabilidad Financiera (AC5):** Los pagos registrados con estado `PAID` son financieramente inmutables. La cancelación de una suscripción asociada no altera el estado de sus pagos `PAID`, garantizando la consistencia de los balances de caja. Ante un error operativo de carga imputado directamente al cobro, el pago se marca como `CANCELLED` para preservar la auditoría financiera, sin eliminarlo físicamente (`DELETE`) de la base de datos.
3. **Validación de Montos:** Todo pago debe tener un monto estrictamente positivo (`amount > 0`). El pago no lleva descuento propio: el único descuento es el de la suscripción (`subscriptions.discount`), que ya se resta del saldo a pagar.
4. **No se cobra más que el saldo pendiente:** El saldo pendiente de una suscripción es $(\text{price} - \text{discount}) - \sum \text{amount}_{\text{PAID}}$. Si el monto de un cobro lo supera (incluido el caso de una suscripción ya saldada), se rechaza con `409 Conflict`. El cálculo del saldo y la inserción del pago se hacen dentro de la misma transacción, bloqueando la fila de la suscripción mientras tanto (`SELECT ... FOR UPDATE`), para que dos cobros simultáneos sobre la misma suscripción no puedan pasarse del saldo. En la pantalla de Caja, el botón de cobro se deshabilita mientras la solicitud está en curso, para evitar un doble envío.
5. **Cajero responsable:** Todo cobro en mostrador guarda el `employee_code` del empleado logueado, para el cierre de caja por turno, también cuando el socio paga con el QR de Mercado Pago. El cajero se fija al crear el cobro (RF-18) y no cambia después: si el pago con QR se confirma minutos más tarde, cuando ese cajero ya cerró sesión o cambió el turno, la confirmación (RF-19) solo cambia el estado y el cobro sigue a nombre de quien lo inició. Solo un pago de Mercado Pago que el socio hace por su cuenta, sin pasar por caja, queda sin cajero (restricción `chk_payment_employee`).
---

### 1.5. Módulo Access (`AccessController`, `AccessService`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría de cada intento de acceso.
- **Criterio de diseño:** Dado que cada acceso constituye un evento de auditoría en una serie temporal (identificado por el número correlativo `access_id`), **no se exponen operaciones CRUD planas** (`PUT` o `DELETE`). Los registros de acceso son inmutables y no se editan ni eliminan manualmente.
- **Entidades involucradas:** `Access` (`access_logs`), `Member` (`members`), `Subscription` (`subscriptions`), `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Roles | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|---|
| **RF-20** | `POST` | `/api/access/validate` | `STAFF` (sesión abierta en la terminal) | **Operación central de negocio.** Recibe la identificación del socio (`member_number`), evalúa en tiempo real la existencia y activación del socio, la cuota al día, la vigencia temporal de la suscripción (momento actual dentro de `[start_date, end_date)`) y el cupo semanal del Plan; persiste el intento en `access_logs`. La vigencia y la deuda se calculan en cada validación, sin mutar estados por vencimiento o mora. El uso semanal se obtiene contando los días distintos con ingreso concedido desde el lunes (hora de Argentina) y el límite proviene de `plans.weekly_limit`. | `{"member_number": "1001"}` | `200 OK` (`GRANTED` o `DENIED`), `400 Bad Request`. |
| **RF-21** | `GET` | `/api/access` | `ADMIN`, `STAFF` | Consulta el registro histórico de accesos para reportes, auditoría y análisis de afluencia. Permite filtrar por rango de fechas, socio (`member_number`) y resultado (`GRANTED` / `DENIED`). | Query params: `page`, `size`, `member_number`, `status`, `from`, `to` | `200 OK` (listado paginado). |

**Reglas de Negocio Formales:**
1. **Motor de Decisión:** la terminal evalúa al socio en este orden y se detiene en la primera condición que falla. Cada intento, concedido o rechazado, se guarda en `access_logs` con el número tipeado (`entered_member_number`) y la hora:
   1. El número tipeado no corresponde a ningún socio: `DENIED` con `MEMBER_NOT_FOUND` y `member_number` vacío. Así recepción puede ver quién intentó entrar con un número que no existe.
   2. El socio está dado de baja (`members.status = 'INACTIVE'`): `DENIED` con `MEMBER_INACTIVE`.
   3. No tiene una suscripción vigente en este momento (`start_date <= ahora < end_date` y `status = 'ACTIVE'`): `DENIED` con `NO_ACTIVE_SUBSCRIPTION`.
   4. Tiene suscripción vigente pero no está al día con los pagos (regla 3): `DENIED` con `PAYMENT_OVERDUE`.
   5. Ya usó los días de la semana que permite su plan (`plans.weekly_limit`; vacío es pase libre): `DENIED` con `WEEKLY_LIMIT_REACHED`.
   6. Si pasa todo: `GRANTED`, con la suscripción vigente en `subscription_number`. En los rechazos 4 y 5 también se guarda esa suscripción, para saber cuál estaba impaga o sin cupo.

   **Reingreso en el mismo día:** el paso 5 cuenta los días distintos de la semana incluyendo el de hoy. Si el socio ya entró hoy, ese día ya está contado y volver a entrar no lo agota. Por ejemplo, Ana tiene 3 días por semana y ya entró el lunes, el martes y el miércoles a la mañana. Si vuelve el miércoles a la tarde, se le concede, porque ese día ya estaba contado. Si intenta el jueves, se rechaza con `WEEKLY_LIMIT_REACHED`.

   La vigencia y la deuda se evalúan en cada validación; no se actualiza ningún estado por vencimiento o falta de pago. RF-20 responde `200 OK` tanto si concede como si rechaza, incluido el número inexistente.
2. **Inmutabilidad de Auditoría:** Cada intento de acceso es un evento histórico inmutable. No se exponen operaciones para actualizar o borrar registros de `access_logs`.
3. **Determinación de Cuota al Día y Exención de Pagos (AC4):** Para conceder el acceso (`GRANTED`), el socio debe tener la cuota al día en su suscripción vigente. Se considera al día si la suma de los montos (`amount`) de todos los pagos con estado `PAID` asociados a dicha suscripción cubre el saldo neto pactado: $\sum \text{amount}_{\text{PAID}} \ge (\text{price} - \text{discount})$. Si la suscripción no tiene descuento (`discount` nulo), se toma como 0. Si una suscripción no registra pagos en `payments`, la suma computa como `$0.00`. Por lo tanto, si el saldo neto pactado es `$0.00` (caso de planes becados con `price = 0.00` o bonificaciones del 100% donde `discount = price`), la condición matemática se satisface automáticamente ($0.00 \ge 0.00$) y el acceso es concedido (`GRANTED`) sin requerir comprobantes en `payments` (los cuales exigen estrictamente `amount > 0`).
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

## 2. Módulos de Frontend Panel Administrativo (`gym-frontend-admin`)

### 2.1. Módulo Dashboard (RF-33)
- **Objetivos:** Proveer al administrador y personal autorizado una vista integral y ejecutiva del estado operativo del gimnasio.
- **Funcionalidades documentadas:**
  - Métricas de afluencia diaria y semanal en base al módulo Access.
  - Horarios pico y distribución de visitas según el Plan contratado, mediante `subscriptions.plan_code` y datos de `plans`.
  - Resumen financiero de ingresos mensuales y cobros pendientes del módulo Payment.
  - Total de socios activos y alertas de suscripciones próximas a vencer.
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
  - **GRANTED (Aprobado):** Nombre del socio, Plan vigente, accesos que le quedan en la semana y mensaje de bienvenida.
  - **DENIED (Rechazado):** Mensaje explicativo claro (ej. "Suscripción vencida", "Límite semanal alcanzado", "Socio inactivo") solicitando acercarse al mostrador administrativo.

---

## 4. Matriz de Trazabilidad Global

Esta matriz vincula de forma directa los Requerimientos Funcionales (RF) detallados en el sistema con sus respectivos Endpoints de resolución técnica y las reglas de negocio que deben cumplir para garantizar la solidez de la arquitectura.

| Código | Requerimiento Funcional | Endpoint / Módulo de Resolución | Regla de Negocio / Criterio de Aceptación Restrictivo |
|---|---|---|---|
| **RF-01** | Autenticación y generación de sesión | `POST /api/auth/login` | Solo para `ADMIN` o `STAFF` con cuenta activa. Valida `work_email` y `password`. Genera JWT inmutable. |
| **RF-02** | Consulta general de socios | `GET /api/members` | Exclusivo para roles administrativos. Soporta paginación y filtros de estado. |
| **RF-03** | Consulta individual de perfil de socio | `GET /api/members/{member_number}` | Búsqueda por número de socio (clave natural de negocio). |
| **RF-04** | Registro de nuevos socios | `POST /api/members` | DNI protegido operativamente. Email o teléfono obligatorios. |
| **RF-05** | Modificación de datos de socios | `PUT /api/members/{member_number}` | Clave natural `member_number` inmutable. |
| **RF-06** | Baja/Alta lógica de socios | `POST /api/members/{member_number}/status` | Actualiza estado (`ACTIVE` / `INACTIVE`) sin borrar historial inmutable. |
| **RF-11** | Listado histórico de suscripciones | `GET /api/subscriptions` | Soporta filtros de vigencia. |
| **RF-12** | Consulta de detalle de suscripción | `GET /api/subscriptions/{id}` | - |
| **RF-13** | Alta de suscripción | `POST /api/subscriptions` | Prohibido solapar fechas de vigencia para un mismo socio. El backend calcula `end_date` sumando un mes a `start_date`. El precio base se toma obligatoriamente de `plans.current_price` y se congela junto con el descuento aplicado. |
| **RF-14** | Modificación de comentarios de suscripción | `PUT /api/subscriptions/{id}` | Solo permite modificar `comments`; ningún otro campo es modificable. |
| **RF-15** | Cancelación lógica de suscripción | `DELETE /api/subscriptions/{id}` | Baja lógica (`status = 'CANCELLED'`) que deniega acceso inmediato, preserva inmutables los pagos `PAID` (sin reintegro automático) y libera el rango temporal de solapamiento. |
| **RF-16** | Auditoría y lista general de pagos | `GET /api/payments` | Filtra por cajero y rango de fechas para el cierre de caja. |
| **RF-17** | Consulta de comprobante específico | `GET /api/payments/{id}` | - |
| **RF-18** | Registro de abonos y comprobantes | `POST /api/payments` | No admite transacciones huérfanas sin referenciar a `subscription_number`. Valida `amount > 0` y rechaza con `409` el monto que supere el saldo pendiente. Guarda el cajero logueado. |
| **RF-19** | Conciliación transaccional (Webhooks) | `PUT /api/payments/{id}` | Registros `PAID` son financieramente inmutables (se marcan `CANCELLED` ante error). |
| **RF-20** | Validación de ingreso en terminal | `POST /api/access/validate` | Rechazo automático por inactividad, suscripción vencida, tope semanal alcanzado o cuota impaga ($\sum \text{amount}_{\text{PAID}} < \text{price} - \text{discount}$). |
| **RF-21** | Historial de auditoría de ingresos | `GET /api/access` | Estrictamente lectura. Operaciones CRUD (`PUT`/`DELETE`) inhabilitadas. |
| **RF-22** | Catálogo general de planes | `GET /api/plans` | Lista registros del catálogo `plans` con sus datos. |
| **RF-23** | Consulta de plan por código | `GET /api/plans/{plan_code}` | Consulta por clave natural `plan_code`. |
| **RF-24** | Creación de nuevos planes | `POST /api/plans` | Exclusivo `ADMIN`. Valida código único y restricciones documentadas de datos. |
| **RF-25** | Modificación de datos de planes | `PUT /api/plans/{plan_code}` | Actualiza datos del catálogo; los cambios de precio no alteran los snapshots históricos en `subscriptions.price`. |
| **RF-33** | Visualización métricas financieras | *Frontend / Dashboard* | Consolida cálculos cruzados de Accesos y Pagos. |
| **RF-34** | Interfaces de Gestión Administrativa | *Frontend / Panel ABM* | Consumo de toda la API protegido vía Bearer Token JWT. |
| **RF-35** | Control de puerta y validación visual | *Frontend / Terminal* | Proporciona feedback semántico en tiempo real (Verde/Rojo). |
