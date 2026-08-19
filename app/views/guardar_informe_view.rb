require "gtk4"
require "fileutils"

class GuardarInformeView

  def initialize(application, ruta_origen:, nombre_sugerido:, on_guardado:, on_cancelar:)
    @application = application
    @ruta_origen = ruta_origen
    @nombre_sugerido = nombre_sugerido
    @on_guardado = on_guardado
    @on_cancelar = on_cancelar

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Guardar informe"
    @ventana.set_default_size(650, 220)

    principal = Gtk::Box.new(:vertical, 15)

    principal.margin_top = 30
    principal.margin_bottom = 30
    principal.margin_start = 30
    principal.margin_end = 30

    titulo = Gtk::Label.new("Guardar informe")
    titulo.add_css_class("title-2")

    etiqueta = Gtk::Label.new("Nombre del archivo")
    etiqueta.halign = :start

    @nombre_entry = Gtk::Entry.new
    @nombre_entry.text = @nombre_sugerido
    @nombre_entry.hexpand = true

    botones = Gtk::Box.new(:horizontal, 10)
    botones.halign = :end

    boton_cancelar = Gtk::Button.new(label: "Cancelar")
    boton_guardar = Gtk::Button.new(label: "Guardar")

    boton_cancelar.signal_connect("clicked") do
      @ventana.close
      @on_cancelar.call
    end

    boton_guardar.signal_connect("clicked") do
      guardar
    end

    botones.append(boton_cancelar)
    botones.append(boton_guardar)

    principal.append(titulo)
    principal.append(etiqueta)
    principal.append(@nombre_entry)
    principal.append(botones)

    @ventana.child = principal
  end

  def guardar
    nombre = @nombre_entry.text.strip

    if nombre.empty?
      mostrar_error("Debes introducir un nombre de archivo.")
      return
    end

    nombre += ".pdf" unless nombre.downcase.end_with?(".pdf")

    dialogo = Gtk::FileChooserNative.new(
      "Guardar informe",
      @ventana,
      :save,
      "Guardar",
      "Cancelar"
    )

    dialogo.current_name = nombre

    dialogo.signal_connect("response") do |_, respuesta|

      if respuesta == :accept

        archivo = dialogo.file

        if archivo.nil?
          mostrar_error("No se ha seleccionado una ubicación.")
        else
          ruta_destino = archivo.path

          guardar_archivo(ruta_destino)
        end

      else
        puts "Guardado cancelado"
      end

      dialogo.destroy
    end

    dialogo.show
  end

  def guardar_archivo(ruta_destino)

    begin

      FileUtils.cp(
        @ruta_origen,
        ruta_destino
      )

      puts
      puts "========================================"
      puts "INFORME GUARDADO"
      puts "========================================"
      puts "Origen:"
      puts @ruta_origen
      puts
      puts "Destino:"
      puts ruta_destino
      puts
      puts "Tamaño:"
      puts File.size(ruta_destino)
      puts "========================================"

      @ventana.close

      @on_guardado.call(ruta_destino)

    rescue StandardError => e

      puts
      puts "ERROR AL GUARDAR"
      puts e.class
      puts e.message
      puts e.backtrace
      puts

      mostrar_error(
        "No se ha podido guardar el informe.\n\n#{e.message}"
      )

    end
  end

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
