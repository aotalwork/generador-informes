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

    titulo = Gtk::Label.new("GENERAR INFORME")
    titulo.add_css_class("page-title")

    tipo = Gtk::Label.new("Tipo: #{@tipo.nombre}")
    tipo.halign = :start

    @estado = Gtk::Label.new("El informe está listo para generar.")
    @estado.add_css_class("page-subtitle")

    generar = Gtk::Button.new(label: "Generar vista previa")
    guardar = Gtk::Button.new(label: "Generar y guardar PDF")
    firmar = Gtk::Button.new(label: "Generar y firmar con AutoFirma")
    volver = Gtk::Button.new(label: "Volver al formulario")

    generar.hexpand = true
    guardar.hexpand = true
    firmar.hexpand = true
    volver.hexpand = true

    # Estilos CSS
    generar.add_css_class("suggested-action")
    guardar.add_css_class("secondary")
    firmar.add_css_class("secondary")
    volver.add_css_class("secondary")

    generar.signal_connect("clicked") do
      @estado.text = "Vista previa generada correctamente en memoria."
    end

    guardar.signal_connect("clicked") do
      abrir_dialogo_guardar
    end

    firmar.signal_connect("clicked") do
      ejecutar_firma
    end

    volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    box.append(titulo)
    box.append(tipo)
    box.append(@estado)
    box.append(Gtk::Separator.new(:horizontal))
    box.append(generar)
    box.append(guardar)
    box.append(firmar)
    box.append(Gtk::Separator.new(:horizontal))
    box.append(volver)

    @ventana.child = box
  end

  # ==========================================================
  # DIÁLOGO NATIVO DE GUARDADO (GTK4 FileChooserNative)
  # ==========================================================
  def abrir_dialogo_guardar
    dialogo = Gtk::FileChooserNative.new(
      "Guardar Informe de Ratificación",
      @ventana,
      :save,
      "Guardar",
      "Cancelar"
    )

    # Nombre por defecto basado en los datos del afectado si existen
    nombre_sugerido = if @datos["nombre_afectado"]
                        slug = @datos["nombre_afectado"].downcase.gsub(/[^a-z0-9]/, "_")
                        "informe_ratificacion_#{slug}.pdf"
                      else
                        "informe_ratificacion_iml.pdf"
                      end
    dialogo.current_name = nombre_sugerido

    # Filtro para obligar a guardar como PDF
    filtro_pdf = Gtk::FileFilter.new
    filtro_pdf.name = "Documentos PDF (*.pdf)"
    filtro_pdf.add_pattern("*.pdf")
    dialogo.add_filter(filtro_pdf)

    dialogo.signal_connect("response") do |_, respuesta_id|
      if respuesta_id == Gtk::ResponseType::ACCEPT
        ruta_archivo = dialogo.file.path
        @on_guardar.call(ruta_archivo, @datos)
        @estado.text = "Archivo guardado con éxito en:\n#{ruta_archivo}"
      end
      dialogo.destroy
    end

    dialogo.show
  end

  # ==========================================================
  # SIMULACIÓN / INVOCACIÓN DE AUTOFIRMA
  # ==========================================================
  def ejecutar_firma
    @estado.text = "Invocando el cliente de AutoFirma de la Junta de Andalucía..."

    # Aquí puedes añadir temporizadores de GTK para simular la carga
    # o delegar directamente en el callback de tu controlador principal.
    GLib::Timeout.add(1500) do
      @on_firmar.call(@datos)
      @estado.text = "Documento firmado digitalmente de forma correcta (.xsig/.pdf)."
      false # Retornar false destruye el temporizador para que no se repita
    end
  end
end
