# Generador de Informes

Aplicación de escritorio desarrollada en **Ruby + GTK4** para la creación y generación de informes médico-legales en formato PDF.

El proyecto está diseñado con una arquitectura modular que separa la interfaz gráfica, la lógica de negocio, los modelos de datos y la generación documental. Los tipos de informe y sus campos se definen mediante archivos YAML, permitiendo estructurar formularios y documentos sin tener que modificar continuamente el código de la aplicación.

---

## ✨ Características

* 🖥️ Aplicación de escritorio basada en **GTK4**
* 📝 Creación de informes mediante formularios dinámicos
* 🗂️ Definición de tipos de informe mediante **YAML**
* 📄 Generación de documentos **PDF en formato A4**
* 📐 Maquetación profesional mediante **Prawn**
* 📊 Soporte para tablas mediante **Prawn Table**
* 🔤 Uso de fuentes Liberation Serif
* 🏛️ Cabecera y elementos gráficos institucionales
* 🔎 Búsqueda flexible de campos y valores
* 🧩 Arquitectura separada por modelos, servicios, controladores y vistas
* 💾 Selección de ubicación para guardar el PDF generado
* ⚠️ Gestión de errores durante la generación del documento
* 📑 Numeración automática de páginas

---

## 🧠 Arquitectura

El proyecto sigue una arquitectura sencilla y modular:

```text
                    ┌─────────────────────┐
                    │      GTK4 App       │
                    │    Interfaz gráfica │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │    Controllers      │
                    │ Flujo de aplicación │
                    └──────────┬──────────┘
                               │
                ┌──────────────┴──────────────┐
                ▼                             ▼
      ┌─────────────────┐           ┌─────────────────┐
      │     Models      │           │    Services     │
      │ Datos del       │           │ Lógica y PDF    │
      │ informe         │           │                 │
      └─────────────────┘           └────────┬────────┘
                                             │
                                             ▼
                                  ┌────────────────────┐
                                  │    Prawn / PDF     │
                                  └────────────────────┘

             config/tipos_informe.yml
                       │
                       ▼
                Definición de
                formularios e
                informes
```

La aplicación parte de una definición YAML de los tipos de informe, transforma esa configuración en objetos de dominio y utiliza los servicios correspondientes para construir el documento final.

---

## 🏗️ Estructura del proyecto

```text
generador-informes/
│
├── app.rb
│
├── app/
│   ├── controllers/
│   │   └── nuevo_informe_controller.rb
│   │
│   ├── models/
│   │   ├── campo_informe.rb
│   │   └── tipo_informe.rb
│   │
│   ├── services/
│   │   ├── tipo_informe_service.rb
│   │   └── generador_pdf_service.rb
│   │
│   ├── views/
│   │   ├── main_window_view.rb
│   │   ├── nuevo_informe_view.rb
│   │   ├── formulario_informe_view.rb
│   │   ├── cargar_informe_view.rb
│   │   ├── informe_cargado_view.rb
│   │   ├── generar_informe_view.rb
│   │   ├── guardar_informe_view.rb
│   │   ├── firmar_informe_view.rb
│   │   └── resultado_view.rb
│   │
│   └── styles/
│       └── app.css
│
├── assets/
│   ├── fonts/
│   └── escudospain.png
│
├── config/
│   └── tipos_informe.yml
│
├── test_combo.rb
├── Gemfile
├── Gemfile.lock
└── mise.toml
```

---

## ⚙️ Stack tecnológico

| Tecnología           | Uso                                             |
| -------------------- | ----------------------------------------------- |
| **Ruby 3.4.10**      | Lenguaje principal                              |
| **GTK4**             | Interfaz gráfica de escritorio                  |
| **Prawn**            | Generación de documentos PDF                    |
| **Prawn Table**      | Tablas dentro de los informes                   |
| **YAML**             | Configuración de tipos y campos de informe      |
| **Liberation Serif** | Tipografía utilizada en los documentos          |
| **mise**             | Gestión de la versión/configuración del entorno |

Las dependencias principales están declaradas en el `Gemfile`.

---

# 📋 Tipos de informe

Los informes no están definidos directamente en las vistas, sino mediante configuración YAML.

Actualmente existe un tipo de informe orientado a:

> **Informe de ratificación de internamiento involuntario en residencia**

La configuración contempla diferentes fases:

```yaml
fases:
  - inicial
  - complementario
  - definitivo
```

y permite definir campos con diferentes tipos, como:

* texto
* textarea
* fecha
* selección
* radio
* booleano
* multiselección
* secciones

También pueden asociarse frases a determinadas respuestas para transformar respuestas estructuradas del formulario en texto utilizado posteriormente en el documento.

---

## 📝 Flujo de creación

El flujo principal de la aplicación es:

```text
Inicio
  │
  ▼
Ventana principal
  │
  ▼
Nuevo informe
  │
  ▼
Seleccionar tipo de informe
  │
  ▼
Completar formulario
  │
  ▼
Generar PDF
  │
  ▼
Guardar documento
  │
  ▼
Resultado
```

La aplicación utiliza callbacks entre las diferentes vistas para mantener el flujo de navegación.

---

# 📄 Generación del PDF

La generación documental está encapsulada en:

```text
app/services/generador_pdf_service.rb
```

El servicio utiliza **Prawn** y genera documentos en tamaño **A4**. También configura fuentes personalizadas, crea una columna lateral institucional, cabecera, contenido médico-legal, pie de página y bloque de firma.

La estructura del documento generado incluye:

```text
┌───────────────────────────────────────────────┐
│ Administración de Justicia                    │
│                                               │
│ Juzgado / Procedimiento                       │
│                                               │
│ INFORME MÉDICO-FORENSE                        │
│                                               │
│ I. Datos de identificación y clínicos         │
│                                               │
│ II. Exploración psiquiátrica                  │
│                                               │
│ III. Evaluación y dictamen pericial           │
│                                               │
│              Conclusión                        │
│                                               │
│                          Firma del forense    │
│                                               │
│                       Página X de Y            │
└───────────────────────────────────────────────┘
```

El servicio también implementa una búsqueda flexible de campos para permitir cierta tolerancia entre los identificadores definidos en la configuración y los datos recibidos del formulario.

---

# 🔧 Instalación

## Requisitos

Necesitas tener instalado:

* Ruby **3.4.10**
* GTK4 y sus dependencias del sistema
* Bundler
* Las dependencias necesarias para compilar/utilizar la gema `gtk4`

La versión de Ruby está definida explícitamente en el proyecto:

```ruby
ruby "3.4.10"
```

---

## 1. Clonar el repositorio

```bash
git clone https://github.com/aotalwork/generador-informes.git
cd generador-informes
```

## 2. Instalar las dependencias

```bash
bundle install
```

## 3. Ejecutar la aplicación

```bash
bundle exec ruby app.rb
```

La aplicación inicializa `Gtk::Application`, carga los estilos CSS y muestra la ventana principal.

---

# 🧪 Pruebas

El repositorio incluye actualmente un script de pruebas/validación:

```text
test_combo.rb
```

Puede ejecutarse con:

```bash
bundle exec ruby test_combo.rb
```

---

# 🎨 Personalización

Los estilos de la interfaz están separados del código Ruby:

```text
app/styles/app.css
```

Los tipos de informe se pueden modificar desde:

```text
config/tipos_informe.yml
```

Esto permite ampliar la aplicación incorporando nuevos tipos de informes, campos, opciones y frases sin tener que concentrar toda la configuración dentro de las vistas.

Por ejemplo:

```yaml
- id: nuevo_informe
  nombre: Nuevo tipo de informe
  descripcion: Descripción del informe
  area: otra_area
  version: 1
  activo: true

  campos:
    - id: nombre
      nombre: Nombre
      tipo: texto
      obligatorio: true
```

---

# 🧩 Diseño modular

Una de las ideas principales del proyecto es evitar que la lógica de generación documental dependa directamente de la interfaz.

### Models

Representan conceptos del dominio:

```text
CampoInforme
TipoInforme
```

### Services

Contienen lógica reutilizable:

```text
TipoInformeService
GeneradorPdfService
```

### Controllers

Gestionan determinadas operaciones del flujo de aplicación:

```text
NuevoInformeController
```

### Views

Gestionan las diferentes pantallas de GTK4:

```text
MainWindowView
NuevoInformeView
FormularioInformeView
GuardarInformeView
ResultadoView
...
```

Esta separación facilita la evolución del proyecto y permite incorporar nuevos tipos de informes sin convertir la aplicación principal en un único archivo monolítico.

---

# 🔐 Consideraciones

El proyecto está orientado a la generación de documentación médico-legal y puede manejar información potencialmente sensible.

Si se utiliza con datos reales, deben establecerse las medidas correspondientes de:

* protección de datos personales
* control de acceso al equipo
* almacenamiento seguro de documentos
* gestión de copias de seguridad
* eliminación segura de documentos temporales
* cumplimiento de la normativa aplicable

La aplicación genera inicialmente el PDF en un directorio temporal antes de pasar al flujo de guardado.

---

# 🚀 Roadmap

Algunas posibles líneas de evolución del proyecto:

* [ ] Completar la carga de informes existentes
* [ ] Implementar persistencia de informes
* [ ] Incorporar firma digital
* [ ] Añadir más tipos de informe
* [ ] Mejorar la validación de formularios
* [ ] Añadir previsualización del PDF
* [ ] Incorporar tests automatizados más completos
* [ ] Mejorar accesibilidad de la interfaz
* [ ] Añadir exportación y gestión avanzada de documentos
* [ ] Crear un sistema de plantillas reutilizables
* [ ] Incorporar versionado de los modelos de informe

---

# 🎯 Objetivo del proyecto

**Generador de Informes** nace con el objetivo de proporcionar una herramienta de escritorio estructurada para transformar información introducida mediante formularios en documentos PDF profesionales y consistentes.

La configuración mediante YAML y la separación entre interfaz, dominio y generación documental permiten construir una base extensible para diferentes tipos de informes.

---

## 👤 Autor

**Arantzazu Otal Alberro**

Desarrolladora especializada en Ruby y desarrollo de aplicaciones.

---

## 📌 Estado

**En desarrollo activo.**

El proyecto continúa evolucionando hacia una herramienta más completa para la creación, gestión y generación de documentación estructurada.

---

## 📄 Licencia

No se ha especificado una licencia de código abierto en el repositorio.

Si quieres publicar el proyecto para que terceros puedan utilizarlo o modificarlo, se recomienda definir explícitamente una licencia.
