# TUPAD - Trabajo Final Integrador - Proyecto: Gym Manager

Versión Resumida en [proyecto resumido](docs/proyecto_resumido.md).

Sistema de gestión integral de gimnasio: centraliza la administración de usuarios, inscripciones, pagos y el control de accesos en la entrada.

- **Estado:** En desarrollo
- **Stack:** Spring Boot 4.x + Java 25 · React 19 + TypeScript · PostgreSQL
- **Arquitectura:** Backend REST con autenticación JWT · Frontend dividido en panel administrativo y terminal de acceso

## Integrantes

**Grupo 144**

- Agustín Emiliano Sotelo Carmelich
- Bruno Giuliano Vapore
- Santiago Octavio Varela

**Tutor**: Sebastián Bruselario

## 🔗 Enlaces del Proyecto

* **Repositorio de GitHub:** [Gym Manager - Grupo 144](https://github.com/santiagovOK/TFI_grupo144.git)
* **Documentación de la API (Swagger):** *(Próximamente - Fase de Desarrollo)*
* **Despliegue en la nube:** *(Próximamente - Entrega Final)*
---

## Descripción del Proyecto

Los gimnasios gestionan sus operaciones de forma manual o con herramientas no integrales: planillas para usuarios, registros en papel para accesos, libros contables para pagos, sin un sistema centralizado. Esto genera falta de control sobre quién accede y cuándo, dificultad para gestionar inscripciones, pagos manuales sin auditoría e imposibilidad de tomar decisiones basadas en datos de uso.

**Gym Manager** es un proyecto de **inventiva propia** que consiste en una plataforma web full-stack para centralizar la gestión de un gimnasio: incluye un panel de administración para el personal y una terminal de acceso en la puerta principal para validar entradas por DNI (o número de socio).

### Objetivo general

Desarrollar un sistema de gestión de gimnasio que automatice las operaciones diarias del negocio y centralice el control de usuarios, suscripciones y acceso.

### Objetivos específicos

- Centralizar la gestión de usuarios (registro, edición, activación/desactivación).
- Gestionar inscripciones con modalidades diferenciadas (acceso ilimitado, limitado a 2 o 3 veces por semana).
- Registrar y controlar pagos asociados a cada inscripción.
- Validar accesos en la puerta principal mediante DNI/número de socio con reglas de negocio.
- Diseñar una arquitectura escalable que permita incorporar funcionalidades futuras sin reestructurar sus módulos estructurales.

---

## Stack Tecnológico

| Capa | Tecnología |
|------|-----------|
| **Frontend Admin** | React 19+ · TypeScript · Tailwind CSS · Chakra UI |
| **Frontend Access** | React 19+ · TypeScript · Tailwind CSS |
| **Backend** | Spring Boot 4.x · Java 25 (LTS) |
| **ORM** | Hibernate / JPA |
| **Base de datos** | PostgreSQL (esquema manual) |
| **Autenticación** | Spring Security + JWT |
| **Documentación de API** | SpringDoc OpenAPI 3.x (Swagger) |
| **Tests** | JUnit 5 · Mockito · REST Assured |
| **Build tool (Backend)** | Gradle |
| **Plataforma de despliegue** | Render (Backend) · Vercel (Frontend) · Neon (PostgreSQL) |

---

## Plan de Trabajo / Hoja de Ruta

- **1.ª Entrega (30/08):** Propuesta de proyecto, plan de trabajo (stack tecnológico y plataformas) y repositorio GitHub.
- **2.ª Entrega (27/09):** Diseño de arquitectura, esquema de la base de datos y lista de módulos a desarrollar.
- **Entrega Final (14/11):** Repositorio completo (código, BD), despliegue online funcionando, documentación escrita y video explicativo.
- **Defensa Oral:** Presentación ante el comité.
---

## Arquitectura

```
+-------------------------------------------------------------+
|                 CLIENTES (Navegadores)                       |
|  +-------------------+        +-------------------------+    |
|  | Gym-Admin         |        | Gym-Access Terminal     |    |
|  |   (React)         |        |     (React)             |    |
|  |   :3001           |        |    :3002                |    |
|  +--------+----------+        +------------+------------+    |
|          | HTTP REST                      | HTTP REST        |
|          v                                v                  |
| +-------------------------------------------------------------+
|              Spring Boot Backend (Java)                      |
|   +-----------------------------------------------------+    |
|   |  REST API + JWT Auth + Schema manual                |    |
|   |  :8080                                              |    |
|   |                                                     |    |
|   |  Controllers -> Services -> Repositories            |    |
|   |  (Patrón Layered / Clean Architecture)              |    |
|   +-----------------------------------------------------+    |
|              PostgreSQL                                      |
+-------------------------------------------------------------+
```

---

## Estructura del Proyecto (tentativa)

<details>
<summary>Ver estructura del proyecto</summary>

```
gym-manager/
├── gym-backend/                          # Spring Boot 4.x
│   ├── src/main/java/com/gym/project/
│   │   ├── GymProjectApplication.java    # Punto de entrada principal
│   │   ├── config/                       # Seguridad, CORS, Swagger
│   │   │   ├── CorsConfig.java
│   │   │   └── OpenApiConfig.java
│   │   ├── controllers/                  # Endpoints REST (uno por módulo)
│   │   │   ├── AuthController.java
│   │   │   ├── UserController.java
│   │   │   ├── EnrollmentController.java
│   │   │   ├── PaymentController.java
│   │   │   └── AccessController.java
│   │   ├── services/                     # Lógica de negocio (uno por módulo)
│   │   │   ├── AuthService.java
│   │   │   ├── UserService.java
│   │   │   ├── EnrollmentService.java
│   │   │   ├── PaymentService.java
│   │   │   └── AccessService.java
│   │   ├── repositories/                 # Repositorios JPA (uno por entidad)
│   │   │   ├── UserRepository.java
│   │   │   ├── EnrollmentRepository.java
│   │   │   ├── PaymentRepository.java
│   │   │   └── AccessRepository.java
│   │   ├── models/                       # Entidades JPA (@Entity)
│   │   │   ├── User.java
│   │   │   ├── Enrollment.java
│   │   │   ├── Payment.java
│   │   │   └── Access.java
│   │   ├── enums/                        # Enumeraciones Java
│   │   │   ├── Role.java
│   │   │   ├── Currency.java
│   │   │   ├── Modality.java
│   │   │   └── AccessStatus.java
│   │   └── dto/                          # Objetos de request/response
│   │       ├── LoginRequest.java
│   │       ├── UserDTO.java
│   │       ├── EnrollmentDTO.java
│   │       └── PaymentDTO.java
│   ├── src/main/resources/
│   │   ├── application.yml               # Configuración principal
│   │   └── schema.sql                    # Creación manual de tablas
│   ├── src/test/java/                    # Tests con JUnit + Mockito
│   │   ├── GymProjectApplicationTests.java
│   │   ├── controller/
│   │   └── service/
│   ├── build.gradle                      # Dependencias Gradle
│   ├── settings.gradle                   # Configuración Gradle
│   └── .env                              # Variables de entorno
│
├── gym-frontend-admin/                   # Panel administrativo (React)
│   ├── public/logo.png
│   ├── src/
│   │   ├── components/
│   │   │   ├── ui/                       # Átomos de UI reutilizables
│   │   │   │   ├── Button.tsx
│   │   │   │   ├── Input.tsx
│   │   │   │   ├── Card.tsx
│   │   │   │   └── Modal.tsx
│   │   │   └── layout/
│   │   │       ├── Sidebar.tsx
│   │   │       └── Header.tsx
│   │   ├── pages/
│   │   │   ├── Login.tsx
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Users.tsx
│   │   │   ├── Enrollments.tsx
│   │   │   ├── Payments.tsx
│   │   │   └── Accesses.tsx
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   └── useApi.ts
│   │   ├── context/
│   │   │   └── AuthContext.tsx
│   │   ├── services/
│   │   │   └── api.ts                    # Axios instance + interceptors
│   │   └── App.tsx
│   ├── index.html
│   ├── package.json
│   ├── vite.config.ts
│   └── tsconfig.json
│
└── gym-access-terminal/                   # Terminal de acceso (React)
    ├── public/logo.png
    ├── src/
    │   ├── components/
    │   │   ├── AccessCard.tsx
    │   │   └── StatusIndicator.tsx
    │   ├── hooks/
    │   │   └── useAccessValidation.ts
    │   └── App.tsx
    ├── index.html
    ├── package.json
    └── vite.config.ts
```

</details>

---

## Modelo de Datos

Base de datos **PostgreSQL** con esquema manual. El detalle completo de cada entidad, sus atributos y las relaciones está documentado en [`docs/entidades.md`](docs/entidades.md).

### Entidades

| Entidad | Tabla | Descripción |
|---------|-------|-------------|
| `User` | `users` | Socio, personal o administrador del gimnasio |
| `Enrollment` | `enrollment` | Inscripción con modalidad y vigencia |
| `Access` | `access` | Registro de cada intento de ingreso validado |
| `Payment` | `payment` | Pago asociado a una inscripción |

### Relaciones

- `User` ↔ `Enrollment`: relación uno a uno (`@OneToOne`).
- `Enrollment` ↔ `Payment`: relación uno a muchos (`@OneToMany`).
- `Enrollment` ↔ `Access`: relación uno a muchos (`@OneToMany`).

### Enums

| Enum | Valores |
|------|---------|
| `Role` | `ADMIN`, `STAFF`, `USER` |
| `Currency` | `ARS`, `USD` |
| `Modality` | `FREE` (ilimitado), `THREE` (3 por semana), `TWO` (2 por semana) |
| `AccessStatus` | `GRANTED`, `DENIED` |

---

## Endpoints REST

<details>
<summary>Ver Endpoints REST</summary>

| Endpoint | Descripción | Método |
|----------|-------------|--------|
| `POST /api/auth/login` | Autenticar usuario y obtener JWT | POST |
| `GET /api/users` | Listar usuarios (con paginación) | GET |
| `GET /api/users/{id}` | Obtener usuario por ID | GET |
| `PUT /api/users/{id}` | Actualizar usuario | PUT |
| `DELETE /api/users/{id}` | Eliminar usuario | DELETE |
| `POST /api/users/{id}/activate` | Activar/desactivar usuario | POST |
| `GET /api/enrollments` | Listar inscripciones (con paginación) | GET |
| `GET /api/enrollments/{id}` | Obtener inscripción por ID | GET |
| `PUT /api/enrollments/{id}` | Actualizar inscripción | PUT |
| `DELETE /api/enrollments/{id}` | Eliminar inscripción | DELETE |
| `GET /api/payments` | Listar pagos (con paginación) | GET |
| `GET /api/payments/{id}` | Obtener pago por ID | GET |
| `POST /api/payments` | Registrar nuevo pago | POST |
| `PUT /api/payments/{id}` | Actualizar pago | PUT |
| `DELETE /api/payments/{id}` | Eliminar pago | DELETE |
| `GET /api/access` | Listar accesos (con paginación) | GET |
| `GET /api/access/{id}` | Obtener acceso por ID | GET |
| `POST /api/access` | Registrar acceso nuevo | POST |
| `PUT /api/access/{id}` | Actualizar acceso | PUT |
| `DELETE /api/access/{id}` | Eliminar acceso | DELETE |

</details>

---

## Características

### Incluidas (Alcance de la versión inicial)

**1. Gestión Administrativa (Panel Web):**
- Gestión integral de usuarios (Socio, Staff, Admin) con estados de activación.
- Administración de inscripciones bajo modalidades de uso (Pase Libre, 2 o 3 veces por semana).
- Registro manual y seguimiento de pagos asociados a cada inscripción.

**2. Control de Accesos (Terminal Frontend):**
- Validación de ingreso mediante DNI o número de socio en tiempo real.
- Aplicación automática de reglas de negocio (verificación de cuota al día y topes de accesos semanales permitidos).
- Feedback visual claro e inmediato del estado de acceso (Aprobado/Denegado).

**3. Reportes y Estadísticas Avanzadas:**
- Dashboard integral con métricas de asistencia y popularidad de horarios.
- Estadísticas de ingresos monetarios por modalidad y por período.
- Historial detallado de asistencias mensuales por socio.

**4. Comunicaciones:** 
- Envío automático de notificaciones de vencimiento de cuota (vía Email).
- Comunicados masivos (broadcast) por parte del administrador para avisos generales.

**5. Componentes Técnicos y Calidad:**
- Backend RESTful securizado con JWT apoyado sobre base de datos relacional (PostgreSQL).
- Documentación interactiva de la API (SpringDoc OpenAPI 3.x / Swagger).
- Cobertura de tests unitarios y de integración.

**6. Integración Financiera:**
- Pasarelas de pago automatizadas (Mercado Pago) o cobros recurrentes automáticos.

### Excluidas (Fuera de alcance para esta iteración)

- **Área Deportiva:** Planes de entrenamiento, rutinas personalizadas o seguimiento de métricas corporales *(el foco es puramente administrativo)*.
- **Perfil Social:** Perfiles extendidos con fotos, metas de fitness y nivel de experiencia.
- **Hardware / IoT:** Control automatizado de molinetes físicos o puertas magnéticas.*(la terminal aprueba en pantalla, el pase físico es supervisado)*.
- **Comunicaciones Transaccionales/Marketing:** Mensajes de bienvenida, comprobantes de pago automáticos, alertas de inactividad para fidelización y recuperación de contraseñas *(no aplica en V1 ya que los socios no poseen credenciales)*.
- **Integración con WhatsApp:** Envío de notificaciones a través de WhatsApp (se excluye en V1 por la mayor complejidad de su API, dejando solo Email en esta primera iteración).

**Nota sobre escalabilidad:** Aunque estas funcionalidades no se implementan en la primera versión, la base arquitectónica está diseñada para soportarlas a futuro sin reestructuraciones mayores.

---

## Comandos de Desarrollo

### Backend (Gradle)

```bash
# Instalar dependencias y compilar
./gradlew build

# Ejecutar con hot reload
./gradlew bootRun

# Ejecutar tests
./gradlew test

# Compilar y empaquetar como JAR
./gradlew clean build

# Empaquetar como aplicación ejecutable
./gradlew bootJar
```

### Frontend Admin

```bash
npm install
npm run dev          # Development server :3001
npm run build        # Build para producción
```

### Frontend Access

```bash
npm install
npm run dev          # Development server :3002
```

---

## Instalación y Configuración

### Requisitos previos

- Java 25 (LTS)
- PostgreSQL
- Node.js (para los frontend)
- Gradle (se gestiona vía wrapper `./gradlew`)

### Pasos

1. Clonar el repositorio.
2. Inicializar la base de datos PostgreSQL y crear el esquema con `schema.sql`.
3. Configurar las variables de entorno del backend (archivo `.env`):

   ```yaml
   server:
     port: 8080

   spring:
     datasource:
       url: jdbc:postgresql://localhost:5432/gym
       username: gym
       password: [PASSWORD_DE_POSTGRESQL]
       driver-class-name: org.postgresql.Driver
     jpa:
       hibernate:
         ddl-auto: validate
       properties:
         hibernate:
           format_sql: true
           show_sql: false
         open-in-view: false

   default-auth:
     jwt:
       secret: [JWT_SECRET_KEY]
       expiration: "12d"
   ```

4. Ejecutar el backend con `./gradlew bootRun`.
5. Iniciar los frontend con `npm run dev` en cada subproyecto.

### Variables a reemplazar en producción

| Variable | Placeholder | Qué poner |
|----------|-------------|-----------|
| `[PASSWORD_DE_POSTGRESQL]` | Contraseña de la DB | Contraseña real de PostgreSQL |
| `[JWT_SECRET_KEY]` | Clave JWT | Clave aleatoria de 32+ caracteres (p. ej. `openssl rand -hex 32`) |
| `gym` (username) | Nombre de usuario | Cambiar si se prefiere otro |
| `localhost:5432` | Host de la DB | Cambiar por el host/servidor de PostgreSQL |

---

## Roadmap de Implementación

## Fase 1: Backend Spring Boot — Base

<details>
<summary>Ver Fase 1: Backend Spring Boot — Base</summary>

- [ ] Crear proyecto con Gradle (Spring Initializr o `gradle init`).
- [ ] Configurar `build.gradle` con dependencias (Spring Boot 4.x, JPA, Lombok, JWT, Validation, OpenAPI 3.x).
- [ ] Configurar `settings.gradle` con grupo y nombre del proyecto.
- [ ] Configurar `application.yml` (DB connection, server port, security settings).
- [ ] Crear entidades JPA (4 entidades + 4 enums).
- [ ] Crear DTOs para request/response.
- [ ] Crear `schema.sql` manual en PostgreSQL (CREATE TABLES).
- [ ] Configurar Spring Security: habilitar JWT, deshabilitar HTTP basic auth.
- [ ] Crear `JwtTokenProvider` (generar/validar tokens).
- [ ] Crear `JwtAuthenticationFilter` (interceptar requests y validar JWT).

</details>

---

## Fase 2: Backend — Business Logic

<details>
<summary>Ver Fase 2: Backend — Business Logic</summary>

- [ ] Implementar `AuthService` + `AuthController` (login con credenciales + JWT, registro).
- [ ] Implementar `UserService` + `UserController` (CRUD completo, activar/desactivar).
- [ ] Implementar `EnrollmentService` + `EnrollmentController` (CRUD, validar relación 1:1).
- [ ] Implementar `PaymentService` + `PaymentController` (pagos con modalidad y moneda, descuentos).
- [ ] Implementar `AccessService` + `AccessController` (reglas de negocio, conteo semanal).

</details>

---

## Fase 3: Backend — Seguridad y Documentación

<details>
<summary>Ver Fase 3: Backend — Seguridad y Documentación</summary>

- [ ] Configurar Swagger/OpenAPI 3.x (`springdoc-openapi-starter-webmvc-ui`).
- [ ] Implementar interceptor global para validación de JWT.
- [ ] Configurar roles y permisos en endpoints (`@PreAuthorize`).
- [ ] Setup de logging (SLF4J + Logback).
- [ ] Tests unitarios con JUnit 5 + Mockito.
- [ ] Tests de integración con REST Assured.

</details>

---

## Fase 4: Frontend Admin (React)

<details>
<summary>Ver Fase 4: Frontend Admin (React)</summary>

- [ ] Setup proyecto Vite + React 19+ + TypeScript.
- [ ] Configurar Chakra UI como librería de componentes.
- [ ] Configurar Tailwind CSS para estilos custom.
- [ ] Configurar React Router v6 para navegación entre páginas.
- [ ] Crear contexto de autenticación (`AuthContext`).
- [ ] Implementar Login page con form y validación.
- [ ] Dashboard con resumen de usuarios, inscripciones, pagos.
- [ ] Páginas CRUD: Usuarios, Inscripciones, Pagos.
- [ ] Consumo de API del Spring Boot vía Axios.
- [ ] Manejo de errores y loading states.

</details>

---

## Fase 5: Frontend Access (React)

<details>
<summary>Ver Fase 5: Frontend Access (React)</summary>

- [ ] Setup proyecto Vite + React (más simple que el admin).
- [ ] Componente de validación de DNI/tarjeta.
- [ ] Lógica de acceso con reglas de negocio del backend.
- [ ] Feedback visual claro (acceso permitido / negado).
- [ ] Consumo de API para verificar acceso.

</details>

---

## Seguridad

La autenticación y autorización se gestionan con **Spring Security + JWT**, reemplazando completamente el uso manual de Passport y bcrypt.

- **`JwtTokenProvider`**: genera y valida los tokens de acceso.
- **`JwtAuthenticationFilter`**: intercepta las peticiones HTTP y valida el JWT.
- **BCrypt**: las contraseñas se almacenan como hash (`BCryptPasswordEncoder`).
- **Roles**: `ADMIN`, `STAFF`, `USER` controlan el acceso a los endpoints mediante `@PreAuthorize`.

> **Datos sensibles:** en producción reemplazar `[PASSWORD_DE_POSTGRESQL]` y `[JWT_SECRET_KEY]` por valores reales. Generar el secret JWT con una clave aleatoria de 32+ caracteres, por ejemplo `openssl rand -hex 32`.

---

## Tecnologías a aprender y reforzar

| Categoría | Tecnologías |
|-----------|-------------|
| **Java Enterprise** | Spring Boot 4.x, JPA/Hibernate, Gradle, Lombok, Spring Security |
| **React** | Hooks (useState, useEffect, useRef), Context API, React Router v6, Chakra UI, Tailwind CSS |
| **TypeScript** | Interfaces, generics, async/await en frontend |
| **PostgreSQL** | JPA queries, relationships, constraints |
| **Testing** | JUnit 5, Mockito, REST Assured |
| **DevOps básico** | Gradle build, Docker deployment, environment config |

---

## Convención de Commits

Se utiliza **Conventional Commits** en inglés, ver [aquí](docs/conventional_commits.md).


## Licencia

Este proyecto está licenciado bajo la [MIT License](LICENCE.txt).
