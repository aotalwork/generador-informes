require "gtk4"

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

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = @tipo.nombre
    @ventana.set_default_size(700, 650)

    # ==========================================================
    # CONTENEDOR PRINCIPAL
    # ==========================================================

    principal = Gtk::Box.new(:vertical, 10)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 40
    principal.margin_end = 40

    # ==========================================================
    # TÍTULO
    # ==========================================================

    titulo = Gtk::Label.new(@tipo.nombre)

    titulo.add_css_class("page-title")

    titulo.halign = :start

    # ==========================================================
    # DESCRIPCIÓN
    # ==========================================================

    descripcion = Gtk::Label.new(@tipo.descripcion)

    descripcion.wrap = true
    descripcion.halign = :start
    descripcion.add_css_class("page-subtitle")

    principal.append(titulo)
    principal.append(descripcion)

    # ==========================================================
    # SEPARADOR
    # ==========================================================

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
    scroll.hexpand = true

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

    # ==========================================================
    # VOLVER
    # ==========================================================

    boton_volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    # ==========================================================
    # GENERAR
    # ==========================================================

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

    # ==========================================================
    # VENTANA
    # ==========================================================

    @ventana.child = principal
  end

  # ============================================================
  # CREAR CONTROL SEGÚN TIPO
  # ============================================================

  def crear_control(campo)
    case campo.tipo

      # ----------------------------------------------------------
      # TEXTO
      # ----------------------------------------------------------

    when "texto"
      crear_texto

      # ----------------------------------------------------------
      # TEXTAREA
      # ----------------------------------------------------------

    when "textarea"
      crear_textarea

      # ----------------------------------------------------------
      # FECHA
      # ----------------------------------------------------------

    when "fecha"
      crear_fecha

      # ----------------------------------------------------------
      # NÚMERO
      # ----------------------------------------------------------

    when "numero"
      crear_numero

      # ----------------------------------------------------------
      # CHECKBOX
      # ----------------------------------------------------------

    when "checkbox"
      crear_checkbox

      # ----------------------------------------------------------
      # TIPO DESCONOCIDO
      # ----------------------------------------------------------

    else
      Gtk::Entry.new
    end
  end

  # ============================================================
  # CAMPO DE TEXTO
  # ============================================================

  def crear_texto
    control = Gtk::Entry.new

    control.hexpand = true

    control
  end

  # ============================================================
  # CAMPO NUMÉRICO
  # ============================================================

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

  # ============================================================
  # CAMPO FECHA
  # ============================================================

  def crear_fecha
    calendario = Gtk::Calendar.new

    calendario.hexpand = true

    calendario
  end

  # ============================================================
  # CHECKBOX
  # ============================================================

  def crear_checkbox
    control = Gtk::CheckButton.new

    control
  end

  # ============================================================
  # TEXTAREA
  # ============================================================

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

  # ============================================================
  # OBTENER DATOS
  # ============================================================

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

  # ============================================================
  # LEER CONTROL
  # ============================================================

  def leer_control(control, tipo)
    case tipo

      # ----------------------------------------------------------
      # TEXTO
      # ----------------------------------------------------------

    when "texto"
      control.text

      # ----------------------------------------------------------
      # FECHA
      # ----------------------------------------------------------

    when "fecha"
      leer_fecha(control)

      # ----------------------------------------------------------
      # TEXTAREA
      # ----------------------------------------------------------

    when "textarea"
      text_view = control.child

      text_view.buffer.text

      # ----------------------------------------------------------
      # NÚMERO
      # ----------------------------------------------------------

    when "numero"
      control.value

      # ----------------------------------------------------------
      # CHECKBOX
      # ----------------------------------------------------------

    when "checkbox"
      control.active

      # ----------------------------------------------------------
      # DESCONOCIDO
      # ----------------------------------------------------------

    else
      control.respond_to?(:text) ? control.text : nil
    end
  end

  # ============================================================
  # LEER FECHA
  # ============================================================

  def leer_fecha(calendario)
    fecha = calendario.date

    fecha.format("%d/%m/%Y")
  end

  # ============================================================
  # VALIDACIÓN
  # ============================================================

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
    end

    true
  end

  # ============================================================
  # MOSTRAR ERROR
  # ============================================================

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
end