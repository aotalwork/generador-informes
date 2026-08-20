require "gtk4"

class MainWindowView
  def initialize(
    application,
    on_nuevo_informe:,
    on_cargar_informe:,
    on_salir:
  )
    @application = application
    @on_nuevo_informe = on_nuevo_informe
    @on_cargar_informe = on_cargar_informe
    @on_salir = on_salir

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Generador de Informes IML"
    @ventana.set_default_size(600, 450)
    @ventana.resizable = false

    contenedor = Gtk::Box.new(:vertical, 20)

    contenedor.margin_top = 50
    contenedor.margin_bottom = 50
    contenedor.margin_start = 80
    contenedor.margin_end = 80

    titulo = Gtk::Label.new(
      "GENERADOR DE INFORMES IML"
    )

    titulo.add_css_class("title-1")

    subtitulo = Gtk::Label.new(
      "Seleccione una opción"
    )

    boton_nuevo = Gtk::Button.new(
      label: "Nuevo informe"
    )

    boton_cargar = Gtk::Button.new(
      label: "Cargar informe"
    )

    boton_salir = Gtk::Button.new(
      label: "Salir"
    )

    boton_nuevo.set_size_request(300, 60)
    boton_cargar.set_size_request(300, 60)
    boton_salir.set_size_request(300, 60)

    boton_nuevo.signal_connect("clicked") do
      @on_nuevo_informe.call
    end

    boton_cargar.signal_connect("clicked") do
      @on_cargar_informe.call
    end

    boton_salir.signal_connect("clicked") do
      @on_salir.call
    end

    contenedor.append(titulo)
    contenedor.append(subtitulo)
    contenedor.append(boton_nuevo)
    contenedor.append(boton_cargar)
    contenedor.append(boton_salir)

    @ventana.child = contenedor
  end
end
