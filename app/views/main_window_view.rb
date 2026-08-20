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
    @ventana.set_default_size(600, 500)
    @ventana.resizable = false

    # ==========================================================
    # CONTENEDOR PRINCIPAL
    # ==========================================================

    contenedor = Gtk::Box.new(:vertical, 16)

    contenedor.margin_top = 40
    contenedor.margin_bottom = 40
    contenedor.margin_start = 70
    contenedor.margin_end = 70

    # ==========================================================
    # LOGO
    # ==========================================================

    logo_container = Gtk::Box.new(:horizontal, 14)

    logo_container.halign = :center

    logo = Gtk::Picture.new

    ruta_logo = File.expand_path(
      "../../assets/logo.png",
      __dir__
    )
    logo.file = Gio::File.new_for_path(ruta_logo)

    logo.content_fit = :contain

    logo.width_request = 70
    logo.height_request = 70

    logo_container.append(logo)

    # ==========================================================
    # TEXTO DEL LOGO
    # ==========================================================

    logo_texto = Gtk::Box.new(:vertical, 2)

    logo_texto.valign = :center

    logo_titulo = Gtk::Label.new(
      "INSTITUTO DE MEDICINA LEGAL"
    )

    logo_titulo.add_css_class("logo-title")
    logo_titulo.halign = :start

    logo_subtitulo = Gtk::Label.new(
      "Generador de informes"
    )

    logo_subtitulo.add_css_class("logo-subtitle")
    logo_subtitulo.halign = :start

    logo_texto.append(logo_titulo)
    logo_texto.append(logo_subtitulo)

    logo_container.append(logo_texto)

    # ==========================================================
    # TÍTULO
    # ==========================================================



    # ==========================================================
    # SUBTÍTULO
    # ==========================================================

    subtitulo = Gtk::Label.new(
      "Seleccione una opción para continuar"
    )

    subtitulo.add_css_class("page-subtitle")
    subtitulo.halign = :center

    # ==========================================================
    # BOTÓN NUEVO INFORME
    # ==========================================================

    boton_nuevo = Gtk::Button.new(
      label: "Nuevo informe"
    )

    boton_nuevo.set_size_request(300, 55)

    # Igual que los demás botones
    boton_nuevo.add_css_class("secondary")

    boton_nuevo.signal_connect("clicked") do
      @on_nuevo_informe.call
    end

    # ==========================================================
    # BOTÓN CARGAR INFORME
    # ==========================================================

    boton_cargar = Gtk::Button.new(
      label: "Cargar informe"
    )

    boton_cargar.set_size_request(300, 55)

    boton_cargar.add_css_class("secondary")

    boton_cargar.signal_connect("clicked") do
      @on_cargar_informe.call
    end

    # ==========================================================
    # BOTÓN SALIR
    # ==========================================================

    boton_salir = Gtk::Button.new(
      label: "Salir"
    )

    boton_salir.set_size_request(300, 55)

    boton_salir.add_css_class("secondary")

    boton_salir.signal_connect("clicked") do
      @on_salir.call
    end

    # ==========================================================
    # SEPARADOR
    # ==========================================================

    separador = Gtk::Separator.new(:horizontal)

    separador.add_css_class("logo-divider")

    # ==========================================================
    # AÑADIR ELEMENTOS
    # ==========================================================

    contenedor.append(logo_container)

    contenedor.append(separador)


    contenedor.append(subtitulo)

    contenedor.append(boton_nuevo)

    contenedor.append(boton_cargar)

    contenedor.append(boton_salir)

    # ==========================================================
    # VENTANA
    # ==========================================================

    @ventana.child = contenedor
  end
end