require "gtk4"

class GenerarInformeView
  def initialize(
    application,
    tipo,
    datos,
    on_guardar:,
    on_firmar:,
    on_volver:
  )
    @application = application
    @tipo = tipo
    @datos = datos

    @on_guardar = on_guardar
    @on_firmar = on_firmar
    @on_volver = on_volver

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Generar informe"
    @ventana.set_default_size(650, 500)

    box = Gtk::Box.new(:vertical, 15)

    box.margin_top = 40
    box.margin_bottom = 40
    box.margin_start = 50
    box.margin_end = 50

    titulo = Gtk::Label.new(
      "GENERAR INFORME"
    )

    titulo.add_css_class("title-1")

    tipo = Gtk::Label.new(
      "Tipo: #{@tipo.nombre}"
    )

    estado = Gtk::Label.new(
      "El informe está listo para generar."
    )

    generar = Gtk::Button.new(
      label: "Generar informe"
    )

    guardar = Gtk::Button.new(
      label: "Generar y guardar"
    )

    firmar = Gtk::Button.new(
      label: "Generar y firmar con AutoFirma"
    )

    volver = Gtk::Button.new(
      label: "Volver"
    )

    generar.signal_connect("clicked") do
      estado.text = "Informe generado correctamente."
    end

    guardar.signal_connect("clicked") do
      @on_guardar.call
    end

    firmar.signal_connect("clicked") do
      @on_firmar.call
    end

    volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    box.append(titulo)
    box.append(tipo)
    box.append(estado)
    box.append(generar)
    box.append(guardar)
    box.append(firmar)
    box.append(volver)

    @ventana.child = box
  end
end
