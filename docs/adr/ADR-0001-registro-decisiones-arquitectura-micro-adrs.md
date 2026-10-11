# ADR-0001: Registro de Decisiones de Arquitectura mediante Micro-ADRs

* **Fecha:** 2026-10-11
* **Estado:** Aceptado

## Contexto y Problema

Durante el diseño inicial del sistema **Gym Manager**, las justificaciones sobre restricciones físicas del motor PostgreSQL (como índices GiST con `btree_gist`, tipos `TIMESTAMPTZ`, secuencias `SERIAL` frente a `AUTO_INCREMENT` y cláusulas `ON DELETE RESTRICT`), elecciones de patrones de diseño (Party-Role, Ledger, Strategy, Chain of Responsibility, Adapter) y topologías de despliegue se documentaron de forma entrelazada dentro de los artefactos del dominio (`docs/entidades.md`, `docs/modulos.md` y `docs/mockup.md`).

Esta mezcla entre el **qué** exige el negocio y el **cómo** se resuelve técnicamente infringe el principio de aislamiento conceptual del dominio (Heurísticas 7 y 20), dificultando la lectura de las reglas comerciales puras y acoplando el modelo conceptual a tecnologías o proveedores específicos. Al mismo tiempo, eliminar sin más dichas justificaciones durante el saneamiento documental (Épica 0) provocaría la pérdida de memoria arquitectónica del equipo, dejando sin respaldo el porqué de las invariantes declaradas en `gym-backend/src/main/resources/schema.sql` y en las capas de servicio.

Se requiere un mecanismo formal, liviano y versionado junto al código fuente que desacople las decisiones de arquitectura e implementación física respecto del modelo conceptual del dominio, garantizando trazabilidad bidireccional hacia las tareas de ingeniería y los requerimientos funcionales (RF-01 a RF-35).

## Decisión y Justificación

Se adopta el estándar de **Micro-ADRs (Architecture Decision Records)** redactados íntegramente en español técnico formal y alojados en el directorio `docs/adr/`, regidos por el índice maestro `docs/adr/README.md` y la plantilla canónica `docs/adr/0000-plantilla.md`.

La decisión se estructura sobre cuatro pilares normativos:

1. **Separación de Preocupaciones Documentales:**
   * `docs/entidades.md` y `docs/modulos.md` conservan exclusivamente las definiciones conceptuales del negocio, los contratos de interfaz REST y las especificaciones relacionales sin comparativas de motores ni justificaciones de infraestructura.
   * `docs/adr/ADR-XXXX-*.md` concentra el contexto técnico, los fundamentos de ingeniería, los patrones GoF/empresariales aplicados, las particularidades de PostgreSQL y los compromisos (*trade-offs*) asumidos.
2. **Ciclo de Vida Inmutable (Bitácora Histórica):**
   * Toda decisión consensuada nace con el estado `Aceptado`.
   * Los registros son inmutables en su intención histórica: si una decisión evoluciona o se revierte en etapas posteriores, el archivo original no se elimina ni se reescribe su historia; su metadato pasa a `Superado por ADR-XXXX` apuntando al nuevo registro secuencial que la reemplaza.
3. **Evidencia Visual Estandarizada (`Flujo Visual`):**
   * Las decisiones que alteran la topología de clases o tablas, los límites entre capas o el flujo temporal de estados incorporan diagramas en sintaxis **Mermaid** (`flowchart`, `erDiagram`, `classDiagram` o `sequenceDiagram`) renderizables de forma nativa en el repositorio.
4. **Explicitación de Compromisos (`Compensaciones y Consecuencias`):**
   * Cada ADR obliga a declarar al menos dos alternativas evaluadas y descartadas bajo `### Alternativas Descartadas`, y a contrastar explícitamente las `* **Ganancias / Beneficios:**` frente a los `* **Costos / Deuda Técnica:**` y riesgos residuales aceptados.

### Alternativas Descartadas

* **Documento monolítico de arquitectura (`docs/arquitectura.md`):** Se descartó porque un único archivo extenso tiende a desactualizarse rápidamente, genera conflictos de fusión (*merge conflicts*) cuando varios desarrolladores trabajan en paralelo sobre distintas épicas y dificulta referenciar decisiones puntuales e independientes desde las tareas de `organization.md` o desde los Pull Requests.
* **Wiki o herramienta externa no versionada en Git (Confluence / Notion):** Se descartó porque rompe la atomicidad entre el código fuente (`schema.sql`, backend, frontend) y la documentación arquitectónica. En un flujo de revisión por Pull Request, los cambios de diseño deben auditarse en el mismo *commit* e historial de ramas que el código que los materializa.
* **Mantener las justificaciones técnicas incrustadas en `docs/entidades.md` y `docs/modulos.md`:** Se descartó porque contamina las reglas de negocio con detalles de motores relacionales (`SERIAL` vs. `AUTO_INCREMENT`), tipos de lenguaje (`LocalDateTime`, `BigDecimal`) y proveedores de nube, incumpliendo las heurísticas académicas de separación entre el modelo conceptual del problema y la arquitectura de la solución.

## Flujo Visual

```mermaid
flowchart TB
    subgraph Dominio["1. Documentación Conceptual y Contratos"]
        ENT["docs/entidades.md<br/>(Conceptos y Estructura de Datos)"]
        MOD["docs/modulos.md<br/>(Reglas de Negocio y Contratos REST)"]
        MOCK["docs/mockup.md<br/>(Especificación UX y Permisos por Rol)"]
    end

    subgraph ADRs["2. Registro de Decisiones de Arquitectura (docs/adr/)"]
        README["docs/adr/README.md<br/>(Índice y Matriz de Trazabilidad)"]
        TPL["docs/adr/0000-plantilla.md<br/>(Estructura Canónica Micro-ADR)"]
        CORE["ADR-0001 a ADR-0013<br/>(Decisiones Fundacionales y Patrones)"]
        FUT["ADR-0014 a ADR-0019<br/>(Decisiones de Épicas 1 a 9)"]
    end

    subgraph Implementacion["3. Artefactos Físicos Ejecutables"]
        SQL["gym-backend/src/main/resources/schema.sql<br/>(DDL PostgreSQL, CHECKs, GiST, Índices)"]
        BACK["gym-backend/<br/>(Spring Boot, JPA, Servicios, Seguridad)"]
        FRONT["gym-frontend-admin / gym-access-terminal<br/>(Aplicaciones Cliente)"]
    end

    Dominio -->|"Desacopla el 'porqué' técnico"| ADRs
    README --> TPL
    TPL --> CORE
    TPL --> FUT
    CORE -->|"Fundamenta y restringe"| SQL
    CORE -->|"Guía patrones (Party-Role, Strategy, CoR, Adapter)"| BACK
    FUT -->|"Rige pruebas, concurrencia y despliegue"| BACK
    FUT -->|"Rige separación de clientes"| FRONT
```

## Compensaciones y Consecuencias

* **Ganancias / Beneficios:**
  * **Pureza conceptual del dominio:** Permite sanear `docs/entidades.md`, `docs/modulos.md` y `docs/mockup.md` (Tareas 0.1 a 0.7) sin perder ninguna justificación técnica de diseño, reubicándolas en registros específicos y cohesionados.
  * **Trazabilidad auditable por tarea:** Cada tarea de las Épicas 0 a 9 en `organization.md` vincula explícitamente el `ADR asociado` que debe respetar o el `ADR a redactar` que formaliza su diseño, facilitando la defensa académica y la revisión de código.
  * **Versionado atómico y revisión en Pull Requests:** Al residir en archivos Markdown individuales con diagramas Mermaid dentro del repositorio Git, cada decisión evoluciona bajo control de versiones sin depender de servicios externos.
* **Costos / Deuda Técnica:**
  * **Sobrecarga de mantenimiento documental:** Todo cambio arquitectónico relevante (como alterar la estrategia de bloqueo transaccional o el mecanismo de conciliación de pagos) exige redactar un nuevo ADR y actualizar la tabla de estados en `docs/adr/README.md`.
  * **Disciplina de sincronización:** Existe el riesgo de que el código evolucione sin reflejar la superación de un ADR previo; se mitiga incorporando la verificación de impacto en ADRs y contratos dentro de la lista de control de `.github/pull_request_template.md` (Tarea 0.8).
