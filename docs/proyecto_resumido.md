# TUPAD - Trabajo Final Integrador - Proyecto: Gym Manager

Sistema de gestión integral de gimnasio: centraliza la administración de usuarios, inscripciones, pagos y el control de accesos en la entrada.

## Integrantes

**Grupo 144**

- Agustín Emiliano Sotelo Carmelich
- Bruno Giuliano Vapore
- Santiago Octavio Varela

**Tutor**: Sebastián Bruselario

# Idea, alcance y objetivos

## Problema

* **Contexto:** Los gimnasios gestionan sus operaciones de forma manual o con herramientas no integrales: planillas para usuarios, registros en papel para accesos, libros contables para pagos, sin un sistema centralizado.
* **Usuario o cliente:** Administrador del gimnasio, instructores, socios activos e inactivos.
* **Necesidad comprobable:** Falta de control sobre quién accede y cuándo, dificultad para gestionar inscripciones, pagos manuales sin auditoría, imposibilidad de tomar decisiones basadas en datos de uso.
* **Evidencia:** Gimnasios pequeños dependen de plantillas de Excel y papel; los medios y grandes ya tienen software propio, en muchos casos costoso. Existe un nicho de mercado para una solución accesible, modular y fácil de mantener.

## Propuesta

* **Tipo de proyecto:** Inventiva propia.

* **Solución:** Plataforma web full-stack que centraliza la gestión del gimnasio: panel de administración para el personal, terminal de acceso en la puerta principal para validar entradas por DNI (o número de socio).
* **Valor:** Automatización completa de procesos operativos (usuarios, inscripciones, pagos, accesos); control de modalidad con reglas de negocio; información consolidada en un dashboard; escalabilidad sin reestructuraciones mayores.
* **Componente original:** Sistema de validación de accesos por DNI o número de socio con modalidades diferenciadas (acceso ilimitado, 2 o 3 accesos semanales) y conteo automático de uso por período.
* **Posibilidad de transferencia:** Arquitectura modular que permite incorporar pasarelas de pago online, rutinas personalizadas y puertas mecánicas en tiempo real sin reestructurar el núcleo.

## Alcance

### Incluido (Alcance de la versión inicial)

**1. Gestión Administrativa (Panel Web):**
* Gestión integral de usuarios (Socio, Staff, Admin) con estados de activación.
* Administración de inscripciones bajo modalidades de uso (Pase Libre, 2 o 3 veces por semana).
* Registro manual y seguimiento de pagos asociados a cada inscripción.

**2. Control de Accesos (Terminal Frontal):**
* Validación de ingreso mediante DNI o número de socio en tiempo real.
* Aplicación automática de reglas de negocio (verificación de cuota al día y topes de accesos semanales permitidos).
* Feedback visual claro e inmediato del estado de acceso (Aprobado/Denegado).

**3. Reportes y Estadísticas Avanzadas:**
* Dashboard integral con métricas de asistencia y popularidad de horarios.
* Análisis de uso de instalaciones.
* Estadísticas de ingresos monetarios por modalidad y por período.
* Historial detallado de asistencias mensuales por socio.

**4. Componentes Técnicos y Calidad:**
* Backend RESTful securizado con JWT.
* Documentación interactiva de la API (Swagger/OpenAPI 3.x).
* Cobertura de tests unitarios y de integración.

**5. Comunicaciones:**
* Envío automático de recordatorios de vencimiento de cuota por Email o WhatsApp.
* Envío de comunicados masivos (broadcast) por parte del administrador para avisos generales.

### Excluido (Fuera de alcance para esta iteración)

* **Área Deportiva:** Planes de entrenamiento, rutinas personalizadas o seguimiento de métricas corporales *(el foco está en la gestión administrativa)*.
* **Perfil Social:** Perfiles extendidos con fotos, metas de fitness y nivel de experiencia.
* **Integración Financiera:** Pasarelas de pago automatizadas (Mercado Pago, Stripe) o cobros recurrentes *(los pagos se rinden e ingresan manualmente en el sistema)*.
* **Hardware / IoT:** Control automatizado de molinetes físicos o puertas magnéticas vía electrónica *(la terminal aprueba en pantalla, el pase físico es supervisado)*.
* **Comunicaciones Transaccionales/Marketing:** Mensajes de bienvenida, comprobantes de pago automáticos, alertas de inactividad para fidelización y recuperación de contraseñas *(no aplica en V1 ya que los socios no poseen credenciales)*.

## Objetivos

* **Objetivo general:** Desarrollar un sistema de gestión de gimnasio que automatice las operaciones diarias del negocio y centralice el control de usuarios, suscripciones y acceso.
* **Objetivos específicos:**
  * Centralizar la gestión de usuarios (registro, edición, activación/desactivación)
  * Gestionar inscripciones con modalidades diferenciadas (acceso ilimitado, limitado a 2 o 3 veces por semana)
  * Registrar y controlar pagos asociados a cada inscripción
  * Validar accesos en puerta principal mediante DNI/Nº Socio con reglas de negocio.
  * La arquitectura estará pensada para escalar a funcionalidades futuras sin reestructurar sus módulos estructurales.

## Validación

- [ ] El problema es concreto.
- [ ] El producto cabe en los plazos.
- [ ] El alcance está limitado.
- [ ] El tutor validó viabilidad, alcance y tiempos.
- [ ] El comité aprobó la propuesta.





