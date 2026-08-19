require "gtk4"

class NuevoInformeView
  def initialize(application, tipos, on_continuar:, on_volver:)
    @application = application
    @tipos = tipos
    @on_continuar = on_continuar
    @on_volver = on_volver

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Nuevo informe"
    @ventana.set_default_size(600, 400)
    @ventana.resizable = false

    contenedor = Gtk::Box.new(:vertical, 15)

    contenedor.margin_top = 40
    contenedor.margin_bottom = 40
    contenedor.margin_start = 50
    contenedor.margin_end = 50

    titulo = Gtk::Label.new("NUEVO INFORME")
    titulo.add_css_class("title-1")

    descripcion = Gtk::Label.new(
      "Seleccione el tipo de informe"
    )

    @selector = Gtk::ComboBoxText.new

    @tipos.each do |tipo|
      @selector.append(tipo.id, tipo.nombre)
    end

    # Seleccionar el primero por defecto
    @selector.active = 0 unless @tipos.empty?

    botones = Gtk::Box.new(:horizontal, 10)

    boton_volver = Gtk::Button.new(label: "Volver")
    boton_continuar = Gtk::Button.new(label: "Continuar")

    boton_volver.hexpand = true
    boton_continuar.hexpand = true

    boton_volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    boton_continuar.signal_connect("clicked") do
      id = @selector.active_id

      next if id.nil?

      tipo = @tipos.find do |elemento|
        elemento.id == id
      end

      next if tipo.nil?

      @ventana.close

      @on_continuar.call(tipo)
    end

    botones.append(boton_volver)
    botones.append(boton_continuar)

    contenedor.append(titulo)
    contenedor.append(descripcion)
    contenedor.append(@selector)
    contenedor.append(botones)

    @ventana.child = contenedor
  end
end