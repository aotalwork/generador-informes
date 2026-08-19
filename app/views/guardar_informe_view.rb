require "gtk4"
require "fileutils"

class GuardarInformeView

  def initialize(application, ruta_origen:, nombre_sugerido:, on_guardado:, on_cancelar:)
    @application = application
    @ruta_origen = ruta_origen
    @nombre_sugerido = nombre_sugerido
    @on_guardado = on_guardado
    @on_cancelar = on_cancelar

    @carpeta_destino = nil

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Guardar informe"
    @ventana.set_default_size(650, 320)

    principal = Gtk::Box.new(:vertical, 15)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 30
    principal.margin_end = 30

    titulo = Gtk::Label.new("Guardar informe")
    titulo.add_css_class("title-2")
    titulo.halign = :start

    # -----------------------------
    # Nombre del archivo
    # -----------------------------

    etiqueta_nombre = Gtk::Label.new("Nombre del archivo")
    etiqueta_nombre.halign = :start

    @nombre_entry = Gtk::Entry.new
    @nombre_entry.text = @nombre_sugerido
    @nombre_entry.hexpand = true

    # -----------------------------
    # Carpeta de destino
    # -----------------------------

    etiqueta_carpeta = Gtk::Label.new("Carpeta de destino")
    etiqueta_carpeta.halign = :start

    @ruta_label = Gtk::Label.new(
      "No se ha seleccionado ninguna carpeta"
    )

    @ruta_label.halign = :start
    @ruta_label.wrap = true
    @ruta_label.hexpand = true

    boton_carpeta = Gtk::Button.new(
      label: "📁  Seleccionar carpeta"
    )

    boton_carpeta.halign = :start
    boton_carpeta.add_css_class("suggested-action")

    boton_carpeta.signal_connect("clicked") do
      abrir_selector_carpeta
    end

    # -----------------------------
    # Botones inferiores
    # -----------------------------

    botones = Gtk::Box.new(:horizontal, 10)
    botones.halign = :end

    boton_cancelar = Gtk::Button.new(
      label: "Cancelar"
    )

    boton_guardar = Gtk::Button.new(
      label: "Guardar"
    )

    boton_guardar.add_css_class("suggested-action")

    boton_cancelar.signal_connect("clicked") do
      @ventana.close
      @on_cancelar.call
    end

    boton_guardar.signal_connect("clicked") do
      guardar
    end

    botones.append(boton_cancelar)
    botones.append(boton_guardar)

    # -----------------------------
    # Montar interfaz
    # -----------------------------

    principal.append(titulo)

    principal.append(etiqueta_nombre)
    principal.append(@nombre_entry)

    principal.append(etiqueta_carpeta)
    principal.append(@ruta_label)
    principal.append(boton_carpeta)

    principal.append(botones)

    @ventana.child = principal
  end

  # ============================================================
  # SELECTOR PROPIO DE CARPETAS
  # ============================================================

  def abrir_selector_carpeta

    carpeta_inicial = @carpeta_destino || File.expand_path("~/Documents")

    @selector_carpeta = SelectorCarpetaView.new(
      @application,

      carpeta_inicial: carpeta_inicial,

      on_seleccionar: ->(ruta) {

        @carpeta_destino = ruta

        @ruta_label.text = "📁  #{ruta}"

        puts
        puts "========================================"
        puts "CARPETA DE DESTINO SELECCIONADA"
        puts "========================================"
        puts ruta
        puts "========================================"
      },

      on_cancelar: -> {
        @ventana.present
      }
    )

    @selector_carpeta.mostrar
  end

  # ============================================================
  # GUARDAR
  # ============================================================

  def guardar

    nombre = @nombre_entry.text.strip

    if nombre.empty?
      mostrar_error(
        "Debes introducir un nombre para el archivo."
      )
      return
    end

    if @carpeta_destino.nil?
      mostrar_error(
        "Debes seleccionar una carpeta de destino."
      )
      return
    end

    nombre += ".pdf" unless nombre.downcase.end_with?(".pdf")

    ruta_destino = File.join(
      @carpeta_destino,
      nombre
    )

    guardar_archivo(ruta_destino)
  end

  # ============================================================
  # COPIAR PDF
  # ============================================================

  def guardar_archivo(ruta_destino)

    begin

      FileUtils.cp(
        @ruta_origen,
        ruta_destino
      )

      unless File.exist?(ruta_destino)
        raise "El archivo no se ha creado."
      end

      puts
      puts "========================================"
      puts "INFORME GUARDADO CORRECTAMENTE"
      puts "========================================"
      puts "Origen:"
      puts @ruta_origen
      puts
      puts "Destino:"
      puts ruta_destino
      puts
      puts "Tamaño: #{File.size(ruta_destino)} bytes"
      puts "========================================"

      @ventana.close

      @on_guardado.call(ruta_destino)

    rescue StandardError => e

      puts
      puts "========================================"
      puts "ERROR AL GUARDAR"
      puts "========================================"
      puts e.class
      puts e.message
      puts "========================================"

      mostrar_error(
        "No se ha podido guardar el informe.\n\n#{e.message}"
      )
    end
  end

  # ============================================================
  # ERROR
  # ============================================================

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

