require "gtk4"
require "date"

class FormularioInformeView
  def initialize(application, tipo, on_volver:, on_generar:)
    @application = application
    @tipo = tipo
    @on_volver = on_volver
    @on_generar = on_generar

    @controles = {}

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  # ==========================================================
  # VENTANA
  # ==========================================================

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = @tipo.nombre
    @ventana.set_default_size(700, 650)

    principal = Gtk::Box.new(:vertical, 10)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 40
    principal.margin_end = 40

    # ==========================================================
    # ENLACE BOE
    # ==========================================================

    enlace_boe = Gtk::Button.new(label: "Consultar BOE ↗")
    enlace_boe.halign = :end
    enlace_boe.add_css_class("link")

    enlace_boe.signal_connect("clicked") do
      url = "https://www.boe.es/buscar/doc.php?id=BOE-A-2023-5368"
      system("xdg-open", url)
    end

    principal.append(enlace_boe)

    # ==========================================================
    # TÍTULO
    # ==========================================================

    titulo = Gtk::Label.new(@tipo.nombre)
    titulo.add_css_class("page-title")

    descripcion = Gtk::Label.new(@tipo.descripcion)
    descripcion.wrap = true
    descripcion.add_css_class("page-subtitle")

    principal.append(titulo)
    principal.append(descripcion)

    separador = Gtk::Separator.new(:horizontal)
    principal.append(separador)

    # ==========================================================
    # FORMULARIO
    # ==========================================================

    formulario = Gtk::Box.new(:vertical, 12)

    @tipo.campos.each do |campo|
      control = crear_control(campo)

      fila = Gtk::Box.new(:vertical, 5)

      etiqueta = Gtk::Label.new(
        campo.obligatorio? ? "#{campo.nombre} *" : campo.nombre
      )

      etiqueta.halign = :start
      etiqueta.add_css_class("form-label")

      fila.append(etiqueta)
      fila.append(control)

      formulario.append(fila)

      @controles[campo.id] = control
    end

    # ==========================================================
    # SCROLL
    # ==========================================================

    scroll = Gtk::ScrolledWindow.new

    scroll.vexpand = true
    scroll.child = formulario

    principal.append(scroll)

    # ==========================================================
    # BOTONES
    # ==========================================================

    botones = Gtk::Box.new(:horizontal, 10)

    boton_volver = Gtk::Button.new(
      label: "Volver"
    )

    boton_generar = Gtk::Button.new(
      label: "Generar informe"
    )

    boton_volver.hexpand = true
    boton_generar.hexpand = true

    boton_volver.add_css_class("secondary")
    boton_generar.add_css_class("secondary")

    boton_volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    boton_generar.signal_connect("clicked") do
      datos = obtener_datos

      if validar(datos)
        @ventana.close
        @on_generar.call(datos)
      end
    end

    botones.append(boton_volver)
    botones.append(boton_generar)

    principal.append(botones)

    @ventana.child = principal
  end

  # ==========================================================
  # CREAR CONTROL SEGÚN TIPO
  # ==========================================================

  def crear_control(campo)
    case campo.tipo
    when "texto"
      entry = Gtk::Entry.new
      entry.hexpand = true
      entry
    when "textarea"
      crear_textarea
    when "fecha"
      crear_fecha
    when "numero"
      crear_numero
    when "booleano"           # <--- NUEVO
      crear_booleano
    when "seleccion"          # <--- NUEVO
      crear_seleccion(campo.opciones)
    when "multiseleccion"     # <--- NUEVO
      crear_multiseleccion(campo.opciones)
    when "checkbox"
      Gtk::CheckButton.new
    else
      Gtk::Entry.new
    end
  end

  # ==========================================================
  # CAMPO NUMÉRICO
  # ==========================================================

  def crear_numero
    adjustment = Gtk::Adjustment.new(
      0.0,
      0.0,
      1_000_000.0,
      1.0,
      10.0,
      0.0
    )

    control = Gtk::SpinButton.new(
      adjustment,
      1.0,
      0
    )

    control.hexpand = true

    control
  end

  # ==========================================================
  # CAMPO FECHA
  #
  # Permite:
  #   1. Escribir 20/08/2026
  #   2. Seleccionar mediante calendario
  # ==========================================================

  def crear_fecha
    contenedor = Gtk::Box.new(:horizontal, 6)

    contenedor.hexpand = true

    # ----------------------------------------------------------
    # INPUT DE FECHA
    # ----------------------------------------------------------

    entrada = Gtk::Entry.new

    entrada.placeholder_text = "dd/mm/aaaa"
    entrada.hexpand = true

    entrada.add_css_class("date-entry")

    # ----------------------------------------------------------
    # BOTÓN CALENDARIO
    # ----------------------------------------------------------

    boton = Gtk::Button.new(
      label: "📅"
    )

    boton.add_css_class("date-button")

    boton.set_size_request(48, 40)

    boton.signal_connect("clicked") do
      mostrar_calendario(entrada)
    end

    # ----------------------------------------------------------
    # AÑADIR
    # ----------------------------------------------------------

    contenedor.append(entrada)
    contenedor.append(boton)

    contenedor
  end

  # ==========================================================
  # CALENDARIO
  # ==========================================================

  def mostrar_calendario(entrada)
    dialogo = Gtk::Window.new

    dialogo.title = "Seleccionar fecha"
    dialogo.modal = true
    dialogo.transient_for = @ventana

    dialogo.set_default_size(320, 320)
    dialogo.resizable = false

    contenedor = Gtk::Box.new(:vertical, 10)

    contenedor.margin_top = 15
    contenedor.margin_bottom = 15
    contenedor.margin_start = 15
    contenedor.margin_end = 15

    calendario = Gtk::Calendar.new

    calendario.hexpand = true
    calendario.vexpand = true

    boton_aceptar = Gtk::Button.new(
      label: "Seleccionar fecha"
    )

    boton_aceptar.add_css_class("secondary")

    boton_aceptar.signal_connect("clicked") do
      fecha = calendario.date

      texto = fecha.format("%Y-%m-%d")

      fecha_ruby = Date.strptime(
        texto,
        "%Y-%m-%d"
      )

      entrada.text = fecha_ruby.strftime(
        "%d/%m/%Y"
      )

      dialogo.close
    end

    contenedor.append(calendario)
    contenedor.append(boton_aceptar)

    dialogo.child = contenedor

    dialogo.present
  end

  # ==========================================================
  # TEXTAREA
  # ==========================================================

  def crear_textarea
    contenedor = Gtk::ScrolledWindow.new

    contenedor.set_min_content_height(120)
    contenedor.set_min_content_width(400)

    text_view = Gtk::TextView.new

    text_view.wrap_mode = :word_char
    text_view.vexpand = true
    text_view.hexpand = true

    contenedor.child = text_view

    contenedor
  end

  # ==========================================================
  # OBTENER DATOS
  # ==========================================================

  def obtener_datos
    datos = {}

    @tipo.campos.each do |campo|
      control = @controles[campo.id]

      datos[campo.id] = leer_control(
        control,
        campo.tipo
      )
    end

    datos
  end

  # ==========================================================
  # LEER CONTROL
  # ==========================================================

  def leer_control(control, tipo)
    case tipo
    when "texto"
      control.text
    when "fecha"
      leer_fecha(control)
    when "textarea"
      text_view = control.child
      text_view.buffer.text
    when "numero"
      control.value
    when "booleano"           # <--- NUEVO
      leer_booleano(control)
    when "seleccion"          # <--- NUEVO
      leer_seleccion(control)
    when "multiseleccion"     # <--- NUEVO
      leer_multiseleccion(control)
    when "checkbox"
      control.active
    else
      control.respond_to?(:text) ? control.text : nil
    end
  end
  # ==========================================================
  # EXTRACCIÓN Y LECTURA DE DATOS (AÑADIR ESTO)
  # ==========================================================

  def leer_booleano(contenedor)
    radio_si = contenedor.first_child
    radio_si.active?
  end

  # ---> ESTE ES EL MÉTODO QUE FALTA Y LANZA EL CRASH <---
  def leer_seleccion(dropdown)
    posicion = dropdown.selected
    return "" if posicion == Gtk::INVALID_LIST_POSITION

    dropdown.model.get_string(posicion)
  end

  # ---> ASEGÚRATE DE TENER TAMBIÉN ESTE PARA LA MULTISELECCIÓN <---
  def leer_multiseleccion(contenedor)
    seleccionados = []
    check = contenedor.first_child
    while check
      if check.respond_to?(:active?) && check.active?
        seleccionados << check.label
      end
      check = check.next_sibling
    end
    seleccionados
  end

  # ==========================================================
  # LEER FECHA
  # ==========================================================

  def leer_fecha(contenedor)
    entrada = contenedor.first_child

    valor = entrada.text.to_s.strip

    return "" if valor.empty?

    begin
      fecha = Date.strptime(
        valor,
        "%d/%m/%Y"
      )

      fecha.strftime("%d/%m/%Y")

    rescue ArgumentError
      valor
    end
  end

  # ==========================================================
  # VALIDACIÓN
  # ==========================================================

  def validar(datos)
    @tipo.campos.each do |campo|
      next unless campo.obligatorio?

      valor = datos[campo.id]

      if valor.nil? || valor.to_s.strip.empty?
        mostrar_error(
          "El campo '#{campo.nombre}' es obligatorio."
        )

        return false
      end

      # --------------------------------------------------------
      # Validación específica de fecha
      # --------------------------------------------------------

      if campo.tipo == "fecha"
        begin
          Date.strptime(
            valor.to_s,
            "%d/%m/%Y"
          )
        rescue ArgumentError
          mostrar_error(
            "El campo '#{campo.nombre}' debe tener " \
              "el formato dd/mm/aaaa."
          )

          return false
        end
      end
    end

    true
  end

  # ==========================================================
  # MOSTRAR ERROR
  # ==========================================================

  def mostrar_error(mensaje)
    dialogo = Gtk::MessageDialog.new(
      transient_for: @ventana,
      modal: true,
      message_type: :error,
      buttons_type: :close,
      text: mensaje
    )

    dialogo.signal_connect("response") do
      dialogo.close
    end

    dialogo.present
  end

  # ==========================================================
  # CAMPO BOOLEANO (Pintado como Radio Buttons Sí / No)
  # ==========================================================
  # ==========================================================
  # CAMPO BOOLEANO (Pintado como Radio Buttons Sí / No)
  # ==========================================================
  def crear_booleano
    contenedor = Gtk::Box.new(:horizontal, 15)

    # Se pasa la etiqueta como argumento posicional directo, sin el hash 'label:'
    radio_si = Gtk::CheckButton.new("Sí")
    radio_no = Gtk::CheckButton.new("No")

    # En GTK4 el comportamiento de grupo de Radio se asigna así:
    radio_no.group = radio_si

    # Por defecto marcamos No para evitar consentimientos accidentales en el IML
    radio_no.active = true

    contenedor.append(radio_si)
    contenedor.append(radio_no)
    contenedor
  end

  # ==========================================================
  # CAMPO MULTISELECCIÓN (Lista de Checkboxes)
  # ==========================================================
  def crear_multiseleccion(opciones)
    contenedor = Gtk::Box.new(:vertical, 6)
    contenedor.margin_start = 10

    opciones.each do |opcion|
      # Se corrige también aquí pasándolo como argumento posicional plano
      check = Gtk::CheckButton.new(opcion)
      contenedor.append(check)
    end

    contenedor
  end


  # ==========================================================
  # CAMPO SELECCIÓN (Desplegable / ComboBox)
  # ==========================================================
  def crear_seleccion(opciones)
    dropdown = Gtk::DropDown.new

    # GTK4 utiliza StringList para cargar arrays de strings nativos
    lista_strings = Gtk::StringList.new(opciones)
    dropdown.model = lista_strings
    dropdown.hexpand = true

    dropdown
  end

  # ==========================================================
  # CAMPO MULTISELECCIÓN (Lista de Checkboxes)
  # ==========================================================
  # ==========================================================
  # CAMPO MULTISELECCIÓN (Lista de Checkboxes)
  # ==========================================================
  def crear_multiseleccion(opciones)
    contenedor = Gtk::Box.new(:vertical, 6)
    contenedor.margin_start = 10

    opciones.each do |opcion|
      # Se elimina la clave 'label:' y se pasa 'opcion' directamente como argumento posicional
      check = Gtk::CheckButton.new(opcion)
      contenedor.append(check)
    end

    contenedor
  end


  def crear_control(campo)
    case campo.tipo
    when "texto"
      entry = Gtk::Entry.new
      entry.hexpand = true
      entry
    when "textarea"
      crear_textarea
    when "fecha"
      crear_fecha
    when "numero"
      crear_numero
    when "booleano"           # <--- NUEVO
      crear_booleano
    when "seleccion"          # <--- NUEVO
      crear_seleccion(campo.opciones)
    when "multiseleccion"     # <--- NUEVO
      crear_multiseleccion(campo.opciones)
    when "checkbox"
      Gtk::CheckButton.new
    else
      Gtk::Entry.new
    end
  end

  # ==========================================================
  # VALIDACIÓN
  # ==========================================================
  def validar(datos)
    errores = []

    @tipo.campos.each do |campo|
      next unless campo.obligatorio?

      valor = datos[campo.id]

      case campo.tipo
      when "multiseleccion"
        if valor.nil? || valor.empty?
          errores << "Debe seleccionar al menos una opción en: #{campo.nombre}"
        end
      when "booleano"
        # Un booleano siempre tendrá true o false seleccionado por el grupo radio,
        # pero es una buena práctica dejar la estructura limpia.
        next
      else
        if valor.nil? || valor.to_s.strip.empty?
          errores << "El campo es obligatorio: #{campo.nombre}"
        end
      end
    end

    if errores.any?
      mostrar_alerta_errores(errores)
      false
    else
      true
    end
  end

  def mostrar_alerta_errores(errores)
    dialogo = Gtk::Window.new
    dialogo.title = "Campos obligatorios incompletos"
    dialogo.modal = true
    dialogo.transient_for = @ventana
    dialogo.set_default_size(400, 200)

    contenedor = Gtk::Box.new(:vertical, 12)
    contenedor.margin_top = 15
    contenedor.margin_bottom = 15
    contenedor.margin_start = 15
    contenedor.margin_end = 15

    label_titulo = Gtk::Label.new("Por favor, corrija los siguientes errores:")
    label_titulo.halign = :start
    contenedor.append(label_titulo)

    texto_errores = errores.map { |e| "• #{e}" }.join("\n")
    label_cuerpo = Gtk::Label.new(texto_errores)
    label_cuerpo.halign = :start
    label_cuerpo.wrap = true
    contenedor.append(label_cuerpo)

    boton_cerrar = Gtk::Button.new(label: "Entendido")
    boton_cerrar.add_css_class("secondary")
    boton_cerrar.signal_connect("clicked") { dialogo.close }
    contenedor.append(boton_cerrar)

    dialogo.child = contenedor
    dialogo.present
  end

end