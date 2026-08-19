require "gtk4"

class FirmarInformeView
  def initialize(
    application,
    on_firmar:,
    on_cancelar:
  )
    @application = application
    @on_firmar = on_firmar
    @on_cancelar = on_cancelar

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Firmar informe"
    @ventana.set_default_size(600, 400)

    box = Gtk::Box.new(:vertical, 15)

    box.margin_top = 40
    box.margin_bottom = 40
    box.margin_start = 50
    box.margin_end = 50

    titulo = Gtk::Label.new(
      "FIRMAR INFORME"
    )

    titulo.add_css_class("title-1")

    informacion = Gtk::Label.new(
      "El documento será firmado mediante AutoFirma."
    )

    firmar = Gtk::Button.new(
      label: "Firmar con AutoFirma"
    )

    cancelar = Gtk::Button.new(
      label: "Cancelar"
    )

    firmar.signal_connect("clicked") do
      @on_firmar.call
    end

    cancelar.signal_connect("clicked") do
      @ventana.close
      @on_cancelar.call
    end

    box.append(titulo)
    box.append(informacion)
    box.append(firmar)
    box.append(cancelar)

    @ventana.child = box
  end
end
