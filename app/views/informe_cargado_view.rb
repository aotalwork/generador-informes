require "gtk4"

class InformeCargadoView
  def initialize(
    application,
    tipo,
    on_volver:,
    on_generar:
  )
    @application = application
    @tipo = tipo
    @on_volver = on_volver
    @on_generar = on_generar

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Informe cargado"
    @ventana.set_default_size(650, 450)

    box = Gtk::Box.new(:vertical, 15)

    box.margin_top = 40
    box.margin_bottom = 40
    box.margin_start = 50
    box.margin_end = 50

    titulo = Gtk::Label.new("INFORME CARGADO")
    titulo.add_css_class("title-1")

    tipo = Gtk::Label.new(
      "Tipo detectado: #{@tipo.nombre}"
    )

    tipo.add_css_class("title-2")

    informacion = Gtk::Label.new(
      "El tipo de informe ha sido detectado automáticamente."
    )

    boton_editar = Gtk::Button.new(
      label: "Editar informe"
    )

    boton_generar = Gtk::Button.new(
      label: "Generar informe"
    )

    boton_volver = Gtk::Button.new(
      label: "Volver"
    )

    boton_editar.signal_connect("clicked") do
      @on_generar.call
    end

    boton_generar.signal_connect("clicked") do
      @on_generar.call
    end

    boton_volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    box.append(titulo)
    box.append(tipo)
    box.append(informacion)
    box.append(boton_editar)
    box.append(boton_generar)
    box.append(boton_volver)

    @ventana.child = box
  end
end
