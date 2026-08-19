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

    principal = Gtk::Box.new(:vertical, 10)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 40
    principal.margin_end = 40

    titulo = Gtk::Label.new(@tipo.nombre)
    titulo.add_css_class("title-1")

    descripcion = Gtk::Label.new(@tipo.descripcion)

    principal.append(titulo)
    principal.append(descripcion)

    separador = Gtk::Separator.new(:horizontal)
    principal.append(separador)

    # Zona de formulario
    formulario = Gtk::Box.new(:vertical, 12)

    @tipo.campos.each do |campo|
      control = crear_control(campo)

      fila = Gtk::Box.new(:vertical, 5)

      etiqueta = Gtk::Label.new(
        campo.obligatorio? ? "#{campo.nombre} *" : campo.nombre
      )

      etiqueta.halign = :start

      fila.append(etiqueta)
      fila.append(control)

      formulario.append(fila)

      @controles[campo.id] = control
    end

    scroll = Gtk::ScrolledWindow.new
    scroll.vexpand = true
    scroll.child = formulario

    principal.append(scroll)

    botones = Gtk::Box.new(:horizontal, 10)

    boton_volver = Gtk::Button.new(label: "Volver")
    boton_generar = Gtk::Button.new(label: "Generar informe")

    boton_volver.hexpand = true
    boton_generar.hexpand = true

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

  def crear_control(campo)
    case campo.tipo
    when "texto"
      Gtk::Entry.new

    when "textarea"
      Gtk::TextView.new

    when "fecha"
      Gtk::Entry.new.tap do |entry|
        entry.placeholder_text = "DD/MM/AAAA"
      end

    when "numero"
      Gtk::SpinButton.new(
        adjustment: Gtk::Adjustment.new(
          0,
          0,
          1_000_000,
          1,
          10,
          0
        ),
        climb_rate: 1,
        digits: 0
      )

    when "checkbox"
      Gtk::CheckButton.new

    else
      Gtk::Entry.new
    end
  end

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

  def leer_control(control, tipo)
    case tipo
    when "texto", "fecha"
      control.text

    when "textarea"
      buffer = control.buffer
      buffer.text

    when "numero"
      control.value

    when "checkbox"
      control.active

    else
      control.respond_to?(:text) ? control.text : nil
    end
  end

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
