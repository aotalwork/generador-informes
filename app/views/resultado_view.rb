require "gtk4"

class ResultadoView

  def initialize(application, titulo:, mensaje:, on_aceptar:)
    @application = application
    @titulo = titulo
    @mensaje = mensaje
    @on_aceptar = on_aceptar

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  def cerrar
    @ventana.close
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = @titulo
    @ventana.set_default_size(500, 300)

    principal = Gtk::Box.new(:vertical, 15)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 30
    principal.margin_end = 30

    titulo = Gtk::Label.new(@titulo)
    titulo.add_css_class("title-2")

    titulo.halign = :center

    mensaje = Gtk::Label.new(@mensaje)
    mensaje.wrap = true
    mensaje.halign = :center
    mensaje.justify = :center
    mensaje.vexpand = true

    boton_aceptar = Gtk::Button.new(
      label: "Aceptar"
    )

    boton_aceptar.halign = :center

    boton_aceptar.signal_connect("clicked") do
      @on_aceptar.call
    end

    principal.append(titulo)
    principal.append(mensaje)
    principal.append(boton_aceptar)

    @ventana.child = principal
  end

end
