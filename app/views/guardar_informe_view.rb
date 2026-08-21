require "gtk4"
require "fileutils"

class GuardarInformeView

  def initialize(
    application,
    ruta_origen:,
    nombre_sugerido:,
    on_guardado:,
    on_cancelar:
  )
    @application = application
    @ruta_origen = ruta_origen
    @nombre_sugerido = nombre_sugerido
    @on_guardado = on_guardado
    @on_cancelar = on_cancelar

    @carpeta_destino = nil
    @ruta_guardada = ""

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Guardar informe"
    @ventana.set_default_size(650, 420)

    principal = Gtk::Box.new(:vertical, 15)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 30
    principal.margin_end = 30

    # ============================================================
    # TÍTULO
    # ============================================================
    @titulo = Gtk::Label.new("Guardar informe")
    @titulo.add_css_class("title-2")
    @titulo.halign = :start

    # ============================================================
    # NOMBRE DEL ARCHIVO
    # ============================================================
    @etiqueta_nombre = Gtk::Label.new("Nombre del archivo")
    @etiqueta_nombre.halign = :start

    @nombre_entry = Gtk::Entry.new
    @nombre_entry.text = @nombre_sugerido
    @nombre_entry.hexpand = true

    # ============================================================
    # CARPETA DE DESTINO
    # ============================================================
    @etiqueta_carpeta = Gtk::Label.new("Carpeta de destino")
    @etiqueta_carpeta.halign = :start

    @ruta_label = Gtk::Label.new("No se ha seleccionado ninguna carpeta")
    @ruta_label.halign = :start
    @ruta_label.wrap = true
    @ruta_label.hexpand = true

    @boton_carpeta = Gtk::Button.new(label: "Seleccionar carpeta...")
    @boton_carpeta.halign = :start

    @boton_carpeta.signal_connect("clicked") do
      seleccionar_carpeta
    end

    # ============================================================
    # ZONA POST-GUARDADO
    # ============================================================
    @zona_guardado = Gtk::Box.new(:vertical, 12)
    @zona_guardado.visible = false

    # Ruta final
    @ruta_guardada_label = Gtk::Label.new("")
    @ruta_guardada_label.halign = :start
    @ruta_guardada_label.wrap = true
    @ruta_guardada_label.hexpand = true

    # Mensaje de éxito
    @exito_guardado = Gtk::Label.new(
      "El informe se ha guardado correctamente."
    )
    @exito_guardado.halign = :start
    @exito_guardado.add_css_class("title-2")

    @zona_guardado.append(@ruta_guardada_label)
    @zona_guardado.append(@exito_guardado)

    # ============================================================
    # BOTONES POST-GUARDADO
    # ============================================================
    @acciones_post_guardado = Gtk::Box.new(:horizontal, 10)
    @acciones_post_guardado.visible = false

    boton_ver_doc = Gtk::Button.new(label: "Ver documento")
    boton_ir_carpeta = Gtk::Button.new(label: "Ir a la carpeta")

    boton_ver_doc.hexpand = true
    boton_ir_carpeta.hexpand = true

    boton_ver_doc.add_css_class("secondary")
    boton_ir_carpeta.add_css_class("secondary")

    boton_ver_doc.signal_connect("clicked") do
      abrir_archivo_nativo(@ruta_guardada) unless @ruta_guardada.empty?
    end

    boton_ir_carpeta.signal_connect("clicked") do
      abrir_carpeta_nativa(@ruta_guardada) unless @ruta_guardada.empty?
    end

    @acciones_post_guardado.append(boton_ver_doc)
    @acciones_post_guardado.append(boton_ir_carpeta)

    # ============================================================
    # BOTONES PRINCIPALES
    # ============================================================
    @botones = Gtk::Box.new(:horizontal, 10)
    @botones.halign = :end

    @boton_cancelar = Gtk::Button.new(label: "Cancelar")
    @boton_guardar = Gtk::Button.new(label: "Guardar")
    @boton_guardar.add_css_class("secondary")

    @boton_finalizar = Gtk::Button.new(label: "Cerrar")
    @boton_finalizar.add_css_class("secondary")
    @boton_finalizar.visible = false

    @boton_cancelar.signal_connect("clicked") do
      @ventana.close
      @on_cancelar.call
    end

    @boton_guardar.signal_connect("clicked") do
      guardar
    end

    @boton_finalizar.signal_connect("clicked") do
      @ventana.close
    end

    @botones.append(@boton_cancelar)
    @botones.append(@boton_guardar)
    @botones.append(@boton_finalizar)

    # ============================================================
    # CONSTRUCCIÓN DE LA INTERFAZ
    # ============================================================
    principal.append(@titulo)
    principal.append(@etiqueta_nombre)
    principal.append(@nombre_entry)
    principal.append(@etiqueta_carpeta)
    principal.append(@ruta_label)
    principal.append(@boton_carpeta)
    principal.append(Gtk::Separator.new(:horizontal))
    principal.append(@zona_guardado)
    principal.append(@acciones_post_guardado)
    principal.append(@botones)

    @ventana.child = principal
  end

  # ============================================================
  # SELECTOR DE CARPETAS
  # ============================================================
  def seleccionar_carpeta
    dialogo = Gtk::FileDialog.new
    dialogo.title = "Seleccionar carpeta"
    dialogo.accept_label = "Seleccionar"

    carpeta_inicial = @carpeta_destino || File.expand_path("~/Documents")
    dialogo.initial_folder = Gio::File.new_for_path(carpeta_inicial)

    dialogo.select_folder(@ventana) do |source, resultado|
      begin
        carpeta = dialogo.select_folder_finish(resultado)

        if carpeta
          @carpeta_destino = carpeta.path
          @ruta_label.text = @carpeta_destino
        end

      rescue GLib::Error => e
        puts "Selector cancelado: #{e.message}"

      rescue StandardError => e
        mostrar_error(
          "No se ha podido seleccionar la carpeta.\n\n#{e.message}"
        )
      end
    end
  end

  # ============================================================
  # GUARDAR
  # ============================================================
  def guardar
    nombre = @nombre_entry.text.strip

    if nombre.empty?
      mostrar_error("Debes introducir un nombre para el archivo.")
      return
    end

    if @carpeta_destino.nil?
      mostrar_error("Debes seleccionar una carpeta de destino.")
      return
    end

    nombre += ".pdf" unless nombre.downcase.end_with?(".pdf")

    ruta_destino = File.join(@carpeta_destino, nombre)

    guardar_archivo(ruta_destino)
  end

  # ============================================================
  # GUARDAR ARCHIVO
  # ============================================================
  def guardar_archivo(ruta_destino)
    begin
      FileUtils.cp(@ruta_origen, ruta_destino)

      unless File.exist?(ruta_destino)
        raise "El archivo no se ha creado."
      end

      @ruta_guardada = ruta_destino

      puts
      puts "========================================"
      puts "INFORME GUARDADO CORRECTAMENTE"
      puts "========================================"
      puts "Origen:"
      puts @ruta_origen
      puts
      puts "Destino:"
      puts @ruta_guardada
      puts
      puts "Tamaño: #{File.size(@ruta_guardada)} bytes"
      puts "========================================"

      mostrar_guardado_correcto

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
  # CAMBIAR INTERFAZ A "GUARDADO CORRECTAMENTE"
  # ============================================================
  def mostrar_guardado_correcto
    # Ocultar toda la parte de configuración del guardado
    @titulo.visible = false
    @etiqueta_nombre.visible = false
    @nombre_entry.visible = false
    @etiqueta_carpeta.visible = false
    @ruta_label.visible = false
    @boton_carpeta.visible = false

    # Mostrar solamente la ruta de destino
    @ruta_guardada_label.text = @ruta_guardada
    @ruta_guardada_label.visible = true

    # Mostrar mensaje de éxito debajo de la ruta
    @zona_guardado.visible = true

    # Mostrar acciones posteriores
    @acciones_post_guardado.visible = true

    # Ocultar Cancelar y Guardar
    @boton_cancelar.visible = false
    @boton_guardar.visible = false

    # Mostrar Cerrar
    @boton_finalizar.visible = true
  end

  # ==========================================================
  # ABRIR ARCHIVO
  # ==========================================================
  def abrir_archivo_nativo(ruta)
    file = Gio::File.new_for_path(ruta)
    context = Gdk::Display.default.app_launch_context
    Gio::AppInfo.launch_default_for_uri(file.uri, context)

  rescue => e
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      system "start \"\" \"#{ruta}\""
    elsif RbConfig::CONFIG['host_os'] =~ /darwin/
      system "open \"#{ruta}\""
    else
      system "xdg-open \"#{ruta}\" &"
    end
  end

  # ==========================================================
  # ABRIR CARPETA
  # ==========================================================
  def abrir_carpeta_nativa(ruta_archivo)
    carpeta = File.dirname(ruta_archivo)

    file = Gio::File.new_for_path(carpeta)
    context = Gdk::Display.default.app_launch_context
    Gio::AppInfo.launch_default_for_uri(file.uri, context)

  rescue => e
    if RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
      system "explorer \"#{carpeta.gsub('/', '\\')}\""
    elsif RbConfig::CONFIG['host_os'] =~ /darwin/
      system "open \"#{carpeta}\""
    else
      system "xdg-open \"#{carpeta}\" &"
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