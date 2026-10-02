# Especificación de Módulos del Sistema y Contratos de Interfaz

Este documento define la arquitectura modular del sistema **Gym Manager**, detallando para cada componente sus objetivos específicos, las entidades del modelo de datos involucradas, los Requerimientos Funcionales (RF) y los contratos formalizados de interfaz REST.

---

**Estado de implementación:** este documento especifica contratos y comportamientos objetivo; su inclusión aquí no afirma que los endpoints, controladores o pantallas estén implementados.

## 1. Módulos de Backend (Spring Boot)

### 1.1. Módulo Auth (`AuthController`, `AuthService`)

- **Objetivos:** Proveer el mecanismo centralizado de autenticación y autorización para el personal administrativo y operativo (roles `ADMIN` y `STAFF`), emitiendo y validando tokens JWT para securizar el resto de los endpoints de la API.
- **Entidades involucradas:** `Employee` (`employees`), `Person` (`persons`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-01** | `POST` | `/api/auth/login` | Autentica credenciales de usuario (work_email laboral y contraseña) y devuelve un token Bearer JWT con los roles asignados. | `{"work_email": "admin@gym.com", "password": "..."}` | `200 OK` (token JWT y datos de sesión), `401 Unauthorized` (credenciales inválidas), `403 Forbidden` (usuario inactivo). |

**Reglas de Negocio Formales:**
1. Solo los usuarios con rol `ADMIN` o `STAFF` y con estado `active = true` están autorizados para autenticarse y recibir un token JWT.
2. Los tokens JWT emitidos son inmutables; cualquier alteración de roles o permisos requerirá un nuevo inicio de sesión.
---

### 1.2. Módulo Actors: Members & Employees (`MemberController`, `EmployeeController`)

- **Objetivos:** Administrar el ciclo de vida de los actores del sistema. Diferencia conceptualmente la gestión de socios deportivos (`Member`) del personal administrativo y operativo (`Employee`), compartiendo la entidad base `Person` para sus datos personales y legales.
- **Entidades involucradas:** `Person` (`persons`), `Member` (`members`), `Employee` (`employees`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-02** | `GET` | `/api/members` | Listado paginado de socios con soporte de filtros por estado (`status`: `ACTIVE`, `OVERDUE`, `INACTIVE`). | Query params: `page`, `size`, `status` | `200 OK` (lista paginada). |
| **RF-03** | `GET` | `/api/members/{member_number}` | Obtiene la ficha de un socio a partir de su clave primaria natural de negocio (`member_number`). | Path param: `member_number` | `200 OK` (objeto MemberDTO), `404 Not Found`. |
| **RF-04** | `POST` | `/api/members` | Registra un nuevo socio en el sistema con su `member_number` único, vinculándolo a sus datos personales en `Person` (`dni` único, contacto obligatorio). | `{"member_number": "1001", "dni": "...", "name": "...", "lastName": "...", "email": "...", "phone": "..."}` | `201 Created` (MemberDTO creado), `400 Bad Request` (validación fallida), `409 Conflict` (número de socio o DNI ya existente). |
| **RF-05** | `PUT` | `/api/members/{member_number}` | Actualiza datos de contacto o personales de un socio existente. | Path param: `member_number`. Body con campos actualizables. | `200 OK`, `400 Bad Request`, `404 Not Found`. |
| **RF-06** | `POST` | `/api/members/{member_number}/status` | Cambia el estado de membresía del socio (`ACTIVE`, `INACTIVE`). | Path param: `member_number`. Body: `{"status": "INACTIVE"}` | `200 OK`, `404 Not Found`. |
| — | `GET` | `/api/employees` | Listado de empleados del gimnasio para administración de personal. | Query params: `page`, `size`, `role` | `200 OK`. |
| — | `POST` | `/api/employees` | Registra un nuevo empleado con credenciales de login (`work_email`, `password`) y rol operativo (`ADMIN`, `STAFF`). | `{"employee_code": "EMP01", "dni": "...", "name": "...", "lastName": "...", "work_email": "admin@gym.com", "email": "...", "phone": "...", "password": "...", "role": "STAFF"}` | `201 Created`, `400 Bad Request`, `409 Conflict` (código de empleado, DNI o work_email ya existente). |

**Reglas de Negocio Formales:**
1. **Canal de contacto mínimo (Privacy & Contact):** Es estrictamente obligatorio registrar al menos un canal de contacto válido (email o teléfono) en la persona base, garantizando la viabilidad de notificaciones.
2. **Aislamiento de Credenciales:** Los socios (`Member`) no poseen contraseña ni rol administrativo en V1. Las credenciales de acceso residen de forma exclusiva en `Employee`.
3. **Número de Socio como Identificador Operativo:** El `member_number` es la clave primaria natural del socio para toda interacción de mostrador y molinete, resguardando el DNI como dato netamente civil y administrativo.
4. **Segregación Semántica de Email:** El correo electrónico civil y de contacto (`persons.email`) no es único y está destinado a la comunicación familiar, permitiendo que menores de edad compartan el correo de sus tutores sin generar conflictos (`409 Conflict`). En contrapartida, la credencial de login y autenticación reside de forma unívoca y obligatoria en el correo corporativo del empleado (`employees.work_email`), garantizando cuentas de acceso individuales, no transferibles y trazables.

### 1.3. Módulo Enrollment (`EnrollmentController`, `EnrollmentService`)

- **Objetivos:** Gestionar los períodos de inscripción de los socios, vinculando el plan seleccionado mediante `plan_code`, estableciendo la vigencia temporal (`start_date`, `end_date`) y consultando `plans.weekly_limit` para el cupo semanal.
- **Entidades involucradas:** `Enrollment` (`enrollment`), `Member` (`members`), `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-07** | `GET` | `/api/enrollments` | Lista inscripciones paginadas, permitiendo filtrar por socio (`member_number`) o estado de vigencia. | Query params: `page`, `size`, `member_number`, `active` | `200 OK`. |
| **RF-08** | `GET` | `/api/enrollments/{id}` | Recupera la información detallada de una inscripción específica por su identificador (`subscription_number`). | Path param: `id` (Integer) | `200 OK`, `404 Not Found`. |
| **RF-09** | `POST` | `/api/enrollments` | Da de alta una nueva inscripción para un socio activo, vinculando el plan elegido (`plan_code`), rango de fechas y condiciones comerciales congeladas (precio y descuento). | `{"member_number": "1001", "plan_code": "THREE_DAYS", "price": 15000.00, "discount": 0.00, "start_date": "...", "end_date": "..."}` | `201 Created`, `400 Bad Request` (fechas incoherentes, precio/descuento inválidos, plan o socio inexistente/inactivo), `409 Conflict` (se superpone con otra inscripción del socio). |
| **RF-10** | `PUT` | `/api/enrollments/{id}` | Modifica parámetros de la inscripción (ej. extensión de vigencia o cambio de plan). | Path param: `id`. Body con atributos modificables. | `200 OK`, `400 Bad Request`, `404 Not Found`, `409 Conflict` (se superpone con otra inscripción del socio). |
| **RF-11** | `DELETE` | `/api/enrollments/{id}` | Realiza la baja lógica de la inscripción (actualiza `status = 'CANCELLED'`), preservando el historial de pagos y accesos asociados. | Path param: `id` | `204 No Content`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Historial, Vigencia y No Solapamiento:** Un socio puede poseer múltiples registros de inscripción (1:N) a modo de historial. El motor de base de datos prohíbe que existan dos inscripciones activas con fechas superpuestas mediante una restricción de exclusión (`no_overlap_enrollment` con `EXCLUDE USING gist`), evaluada exclusivamente sobre registros con `status != 'CANCELLED'`.
2. **Cupo Semanal:** el límite se consulta en el plan asociado (`plans.weekly_limit`) y el uso se calcula contando los accesos `GRANTED` del socio en la semana en curso. La restricción de base de datos requiere un valor no negativo cuando el límite está informado. No se almacena un contador.
3. **Congelamiento de Condiciones Comerciales:** `enrollment.price` conserva un snapshot histórico del `plans.current_price` aplicado al crear la inscripción, junto con el descuento concedido (`discount`). Los cambios posteriores en el catálogo no alteran los valores históricos del registro.
4. **Baja Lógica y Conservación de Auditoría:** La cancelación de una membresía (`DELETE /api/enrollments/{id}`, RF-11) opera como una baja lógica actualizando su estado a `CANCELLED`. De esta forma se respeta la integridad referencial (`ON DELETE RESTRICT`) frente a pagos (`payment`) o registros de acceso (`access`) preexistentes, al tiempo que se libera inmediatamente el rango temporal para permitir la inscripción de un nuevo período sin bloqueos.
---

### 1.4. Módulo Payment (`PaymentController`, `PaymentService`)

- **Objetivos:** Registrar y supervisar los pagos efectuados por los socios para cancelar sus inscripciones. Soporta múltiples transacciones por inscripción (abonos parciales o renovaciones), distintos métodos de pago y estados transaccionales (`PENDING`, `PAID`, `FAILED`, `CANCELLED`), preparando la arquitectura para la integración de pasarelas como Mercado Pago.
- **Entidades involucradas:** `Payment` (`payment`), `Enrollment` (`enrollment`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-12** | `GET` | `/api/payments` | Consulta listado de pagos registrados con paginación y filtros por inscripción (`enrollment_id`), estado o rango de fechas. | Query params: `page`, `size`, `enrollment_id`, `status` | `200 OK`. |
| **RF-13** | `GET` | `/api/payments/{id}` | Obtiene los datos detallados de un comprobante de pago por su número de recibo (`receipt_number`). | Path param: `id` (Integer) | `200 OK`, `404 Not Found`. |
| **RF-14** | `POST` | `/api/payments` | Registra un nuevo cobro asociado a una inscripción. | `{"enrollment_id": "...", "amount": 25000.00, "discount": 0.00, "currency": "ARS", "payment_method": "CASH", "status": "PAID"}` | `201 Created`, `400 Bad Request` (monto inválido `<= 0`, descuento mayor al monto o inscripción inexistente). |
| **RF-15** | `PUT` | `/api/payments/{id}` | Actualiza el estado de una transacción o referencia externa (ej. confirmación de webhook de pago). | Path param: `id`. Body con nuevo estado o datos de conciliación. | `200 OK`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Integridad Transaccional:** Todo registro de cobro debe referenciar de forma obligatoria a una inscripción existente (`enrollment_id`); no se admiten pagos "huérfanos".
2. **Idempotencia y Auditoría:** Los pagos registrados con estado `PAID` son inmutables. Ante un error, el pago se marca como `CANCELLED` para preservar la auditoría financiera, sin eliminarlo (DELETE) de la base de datos.
3. **Validación de Montos:** Todo pago debe tener un monto estrictamente positivo (`amount > 0`) y, en caso de aplicar descuento, este debe ser no negativo y no superar el monto de la transacción (`0 <= discount <= amount`).
---

### 1.5. Módulo Access (`AccessController`, `AccessService`)

- **Objetivos:** Servir como motor transaccional de validación de ingresos en tiempo real en la entrada del gimnasio y mantener el registro histórico inmutable de auditoría de cada intento de acceso.
- **Criterio de diseño:** Dado que cada acceso constituye un evento de auditoría en una serie temporal (identificado por el número correlativo `access_id`), **no se exponen operaciones CRUD planas** (`PUT` o `DELETE`). Los registros de acceso son inmutables y no se editan ni eliminan manualmente.
- **Entidades involucradas:** `Access` (`access`), `Member` (`members`), `Enrollment` (`enrollment`), `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-16** | `POST` | `/api/access/validate` | **Operación central de negocio.** Recibe la identificación del socio (`member_number`), evalúa existencia y activación, cuota al día, vigencia de la inscripción y cupo semanal del Plan; persiste el intento en `access`. El uso semanal se obtiene contando accesos `GRANTED` y el límite proviene de `plans.weekly_limit`. | `{"member_number": "1001"}` | `200 OK` (`GRANTED` o `DENIED`), `400 Bad Request`. |
| **RF-17** | `GET` | `/api/access` | Consulta el registro histórico de accesos para reportes, auditoría y análisis de afluencia. Permite filtrar por rango de fechas, socio (`member_number`) y resultado (`GRANTED` / `DENIED`). | Query params: `page`, `size`, `member_number`, `status`, `from`, `to` | `200 OK` (listado paginado). |

**Reglas de Negocio Formales:**
1. **Motor de Decisión:** el sistema denegará automáticamente el acceso (`DENIED`) si el socio está inactivo, no posee una inscripción vigente en la fecha actual, no tiene la cuota al día, o si ya consumió el cupo semanal de su plan. El cupo se determina mediante `plans.weekly_limit`. Si el número de socio ingresado no existe en el sistema, la validación se rechaza inmediatamente sin persistir el intento en la base de datos (para preservar la integridad referencial), registrando el evento únicamente en los logs de seguridad de la aplicación.
2. **Inmutabilidad de Auditoría:** Cada intento de acceso es un evento histórico inmutable. No se exponen operaciones para actualizar o borrar registros de `access`.
3. **Determinación de Cuota al Día:** Para conceder el acceso (`GRANTED`), el socio debe tener la cuota al día en su inscripción vigente. Se considera al día si la suma de los montos (`amount`) de todos los pagos con estado `PAID` asociados a dicha inscripción cubre el saldo neto pactado: $\sum \text{amount}_{\text{PAID}} \ge (\text{price} - \text{discount})$. Si la inscripción no tiene descuento (`discount` nulo), se toma como 0. Si una inscripción no registra pagos en `payment`, la suma computa como `$0.00`. Por lo tanto, si el saldo neto pactado es `$0.00` (caso de planes becados con `price = 0.00` o bonificaciones del 100% donde `discount = price`), la condición matemática se satisface automáticamente ($0.00 \ge 0.00$) y el acceso es concedido (`GRANTED`) sin requerir comprobantes de pago. Si el saldo pactado es mayor a `$0.00` y la suma de pagos acreditados es insuficiente, el acceso se deniega (`DENIED`) por cuota impaga.
---

### 1.6. Módulo Plans (`PlanController`, `PlanService`)

- **Objetivos:** Administrar el catálogo dinámico `plans`, identificado mediante `plan_code`, con cupos semanales, precios de lista (`current_price`) y estado activo, proveyendo el soporte de backend documentado para la Pantalla 5 de los mockups.
- **Entidades involucradas:** `Plan` (`plans`).
- **Contratos de Interfaz REST:**

| RF | Método | Endpoint | Descripción | Request Body / Parámetros | Códigos de Respuesta |
|---|---|---|---|---|---|
| **RF-21** | `GET` | `/api/plans` | Recupera los registros activos del catálogo `plans`, con sus datos vigentes. | Ninguno | `200 OK`. |
| **RF-22** | `GET` | `/api/plans/{plan_code}` | Obtiene los detalles de un plan por su código natural (`plan_code`). | Path param: `plan_code` | `200 OK`, `404 Not Found`. |
| **RF-23** | `POST` | `/api/plans` | Crea un registro Plan en el catálogo. | `{"plan_code": "WEEKEND", "name": "Pase Fines de Semana", "weekly_limit": 2, "current_price": 12000.00}` | `201 Created`, `400 Bad Request` (código vacío o duplicado, arancel negativo). |
| **RF-24** | `PUT` | `/api/plans/{plan_code}` | Actualiza arancel vigente (`current_price`), cupo semanal o estado de activación de un plan. | Path param: `plan_code`. Body con nuevos valores. | `200 OK`, `400 Bad Request`, `404 Not Found`. |

**Reglas de Negocio Formales:**
1. **Inmutabilidad de Contratos Previos:** Modificar el precio de lista (`current_price`) de un plan no altera bajo ningún concepto las suscripciones ya emitidas (`enrollment.price` congelado al momento del alta).
2. **Conservación Referencial:** Un plan con inscripciones históricas no puede ser borrado físicamente de la base de datos (`ON DELETE RESTRICT`). Las bajas se gestionan de forma lógica mediante el atributo `active = false`.

## 2. Módulos de Frontend Panel Administrativo (`gym-frontend-admin`)

### 2.1. Módulo Dashboard (RF-18)
- **Objetivos:** Proveer al administrador y personal autorizado una vista integral y ejecutiva del estado operativo del gimnasio.
- **Funcionalidades documentadas:**
  - Métricas de afluencia diaria y semanal en base al módulo Access.
  - Horarios pico y distribución de visitas según el Plan contratado, mediante `enrollment.plan_code` y datos de `plans`.
  - Resumen financiero de ingresos mensuales y cobros pendientes del módulo Payment.
  - Total de socios activos y alertas de inscripciones próximas a vencer.
- Estas funcionalidades son requisitos de diseño, no evidencia de que la pantalla o sus endpoints estén implementados.

### 2.2. Módulo ABM (Gestión Administrativa) (RF-19)
- **Objetivos:** Centralizar las operaciones de administración del sistema mediante interfaces responsivas y securizadas por JWT.
- **Funcionalidades documentadas:**
  - **Gestión de Socios y Personal:** Altas, modificaciones, visualización de fichas individuales y gestión de estados consumiendo `/api/members` y `/api/employees`.
  - **Gestión de Inscripciones:** Asignación de planes mediante `plan_code`, prórrogas y monitoreo de vigencia consumiendo los contratos `/api/enrollments`.
  - **Gestión de Cobros:** Registro manual de pagos, emisión de comprobantes internos y seguimiento de estados transaccionales consumiendo `/api/payments`.
  - **Monitor de Accesos:** Vista y reportes históricos de ingresos y rechazos consumiendo `/api/access`.
  - **Configuración Tarifaria y Planes (Pantalla 5 de mockups):** Administración dinámica de Plan (`plan_code`, `weekly_limit`, `current_price`, `active`) mediante los contratos `/api/plans`.
- Las capacidades listadas son contratos documentados; su aparición aquí no implica que las pantallas, controladores o endpoints correspondientes estén implementados.

---

## 3. Módulos de Frontend Terminal de Acceso (`gym-access-terminal`)

### 3.1. Módulo Validación Visual (RF-20)
- **Objetivos:** Ofrecer una interfaz minimalista, autónoma y de respuesta instantánea para la terminal ubicada en el acceso físico del gimnasio.
- **Funcionalidades:**
  - Interfaz de entrada para ingresar el número de socio (`member_number`) mediante teclado numérico o lector de credenciales (preservando el DNI como dato administrativo por privacidad).
  - Consumo del endpoint de negocio `POST /api/access/validate`.
  - **GRANTED (Aprobado):** Nombre del socio, Plan vigente, accesos que le quedan en la semana y mensaje de bienvenida.
  - **DENIED (Rechazado):** Mensaje explicativo claro (ej. "Inscripción vencida", "Límite semanal alcanzado", "Socio inactivo") solicitando acercarse al mostrador administrativo.

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
| **RF-07** | Listado histórico de inscripciones | `GET /api/enrollments` | Soporta filtros de vigencia. |
| **RF-08** | Consulta de detalle de inscripción | `GET /api/enrollments/{id}` | - |
| **RF-09** | Alta de planes / membresías | `POST /api/enrollments` | Prohibido solapar fechas de vigencia para un mismo usuario. Congela precio base pactado y descuento. |
| **RF-10** | Modificación de vigencia o Plan | `PUT /api/enrollments/{id}` | - |
| **RF-11** | Cancelación lógica de membresía | `DELETE /api/enrollments/{id}` | Baja lógica (`status = 'CANCELLED'`) que preserva integridad referencial y libera el rango temporal de solapamiento. |
| **RF-12** | Auditoría y lista general de pagos | `GET /api/payments` | - |
| **RF-13** | Consulta de comprobante específico | `GET /api/payments/{id}` | - |
| **RF-14** | Registro de abonos y comprobantes | `POST /api/payments` | No admite transacciones huérfanas sin referenciar a `enrollment_id`. Valida `amount > 0` y descuento válido. |
| **RF-15** | Conciliación transaccional (Webhooks) | `PUT /api/payments/{id}` | Registros `PAID` son financieramente inmutables (se marcan `CANCELLED` ante error). |
| **RF-16** | Validación de ingreso en terminal | `POST /api/access/validate` | Rechazo automático por inactividad, plan vencido, tope semanal alcanzado o cuota impaga ($\sum \text{amount}_{\text{PAID}} < \text{price} - \text{discount}$). |
| **RF-17** | Historial de auditoría de ingresos | `GET /api/access` | Estrictamente lectura. Operaciones CRUD (`PUT`/`DELETE`) inhabilitadas. |
| **RF-18** | Visualización métricas financieras | *Frontend / Dashboard* | Consolida cálculos cruzados de Accesos y Pagos. |
| **RF-19** | Interfaces de Gestión Administrativa | *Frontend / Panel ABM* | Consumo de toda la API protegido vía Bearer Token JWT. |
| **RF-20** | Control de puerta y validación visual | *Frontend / Terminal* | Proporciona feedback semántico en tiempo real (Verde/Rojo). |
| **RF-21** | Catálogo general de planes | `GET /api/plans` | Lista registros del catálogo `plans` con sus datos. |
| **RF-22** | Consulta de plan por código | `GET /api/plans/{plan_code}` | Consulta por clave natural `plan_code`. |
| **RF-23** | Creación de nuevos planes | `POST /api/plans` | Exclusivo `ADMIN`. Valida código único y restricciones documentadas de datos. |
| **RF-24** | Modificación de datos de planes | `PUT /api/plans/{plan_code}` | Actualiza datos del catálogo; los cambios de precio no alteran los snapshots históricos en `enrollment.price`. |