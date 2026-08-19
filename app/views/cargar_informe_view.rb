require "gtk4"

class CargarInformeView
  def initialize(application, on_volver:, on_cargar:)
    @application = application
    @on_volver = on_volver
    @on_cargar = on_cargar

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Cargar informe"
    @ventana.set_default_size(650, 400)

    box = Gtk::Box.new(:vertical, 15)

    box.margin_top = 40
    box.margin_bottom = 40
    box.margin_start = 50
    box.margin_end = 50

    titulo = Gtk::Label.new("CARGAR INFORME")
    titulo.add_css_class("title-1")

    descripcion = Gtk::Label.new(
      "Seleccione un informe existente"
    )

    archivo = Gtk::FileChooserButton.new(
      title: "Seleccionar informe",
      action: :open
    )

    archivo.hexpand = true

    boton_cargar = Gtk::Button.new(
      label: "Cargar informe"
    )

    boton_volver = Gtk::Button.new(
      label: "Volver"
    )

    boton_cargar.signal_connect("clicked") do
      @on_cargar.call(archivo.file)
    end

    boton_volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    botones = Gtk::Box.new(:horizontal, 10)

    boton_volver.hexpand = true
    boton_cargar.hexpand = true

    botones.append(boton_volver)
    botones.append(boton_cargar)

    box.append(titulo)
    box.append(descripcion)
    box.append(archivo)
    box.append(botones)

    @ventana.child = box
  end
end
