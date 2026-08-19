require "bundler/setup"
require "gtk4"
require "pathname"
require "yaml"
require "tmpdir"

require_relative "app/models/campo_informe"
require_relative "app/models/tipo_informe"

require_relative "app/services/tipo_informe_service"
require_relative "app/services/generador_pdf_service"

require_relative "app/controllers/nuevo_informe_controller"

require_relative "app/views/main_window_view"
require_relative "app/views/nuevo_informe_view"
require_relative "app/views/formulario_informe_view"
require_relative "app/views/cargar_informe_view"
require_relative "app/views/informe_cargado_view"
require_relative "app/views/generar_informe_view"
require_relative "app/views/guardar_informe_view"
require_relative "app/views/firmar_informe_view"
require_relative "app/views/resultado_view"


class GeneradorInformes

  def initialize
    @app = Gtk::Application.new(
      "com.generadorinformes.app",
      :flags_none
    )

    @app.signal_connect("activate") do |application|
      cargar_estilos
      mostrar_ventana_principal(application)
    end
  end


  def ejecutar
    @app.run
  end




def cargar_estilos

  provider = Gtk::CssProvider.new

  ruta = File.expand_path(
    "app/styles/app.css",
    __dir__
  )

  provider.load_from_path(ruta)

  Gtk::StyleContext.add_provider_for_display(
    Gdk::Display.default,
    provider,
    800
  )

end








  private


  def mostrar_ventana_principal(application)

    @ventana_principal = MainWindowView.new(
      application,

      on_nuevo_informe: -> {
        abrir_nuevo_informe(application)
      },

      on_cargar_informe: -> {
        cargar_informe
      },

      on_salir: -> {
        application.quit
      }
    )

    @ventana_principal.mostrar
  end


  def abrir_nuevo_informe(application)

    controller = NuevoInformeController.new

    tipos = controller.tipos

    @ventana_nuevo = NuevoInformeView.new(
      application,
      tipos,

      on_continuar: ->(tipo) {
        tipo_seleccionado(tipo)
      },

      on_volver: -> {
        @ventana_principal.mostrar
      }
    )

    @ventana_nuevo.mostrar
  end


  def tipo_seleccionado(tipo)

    @ventana_formulario = FormularioInformeView.new(
      @app,
      tipo,

      on_volver: -> {
        abrir_nuevo_informe(@app)
      },

      on_generar: ->(datos) {
        generar_informe(tipo, datos)
      }
    )

    @ventana_formulario.mostrar
  end


  def generar_informe(tipo, datos)

    puts
    puts "========================================"
    puts "GENERANDO INFORME"
    puts "========================================"
    puts "Tipo: #{tipo.nombre}"
    puts "Datos:"
    puts datos.inspect
    puts

    ruta = File.join(
      Dir.tmpdir,
      "informe-#{tipo.id}-#{Time.now.strftime("%Y%m%d%H%M%S")}.pdf"
    )

    begin

      GeneradorPdfService
        .new(tipo, datos)
        .generar(ruta)

      puts "PDF generado correctamente:"
      puts ruta
      puts "Tamaño: #{File.size(ruta)} bytes"

      abrir_guardar_informe(tipo, ruta)

    rescue StandardError => e

      puts
      puts "ERROR GENERANDO INFORME"
      puts e.class
      puts e.message
      puts e.backtrace
      puts

      mostrar_error(
        "No se ha podido generar el informe.\n\n#{e.message}"
      )
    end
  end

  def abrir_guardar_informe(tipo, ruta)

    nombre = "informe-#{tipo.id}.pdf"

    @ventana_guardar = GuardarInformeView.new(
      @app,
      ruta_origen: ruta,
      nombre_sugerido: nombre,

      on_guardado: ->(ruta_guardada) {

        puts
        puts "Mostrando resultado de guardado:"
        puts ruta_guardada
        puts

        mostrar_resultado(
          "Informe guardado correctamente",
          "El informe se ha guardado correctamente.\n\n" \
            "Ubicación:\n#{ruta_guardada}"
        )
      },

      on_cancelar: -> {
        @ventana_principal.mostrar
      }
    )

    @ventana_guardar.mostrar
  end

  def mostrar_resultado(titulo, mensaje)

    @resultado_view = ResultadoView.new(
      @app,
      titulo: titulo,
      mensaje: mensaje,

      on_aceptar: -> {

        puts "Cerrando pantalla de resultado"

        @resultado_view.cerrar
        @resultado_view = nil

        @ventana_principal.mostrar
      }
    )

    @resultado_view.mostrar
  end


  def mostrar_error(mensaje)

    dialogo = Gtk::MessageDialog.new(
      transient_for: nil,
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


  def cargar_informe
    puts "Cargar informe"
  end

end


GeneradorInformes.new.ejecutar
