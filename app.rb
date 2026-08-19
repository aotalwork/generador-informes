require "bundler/setup"
require "gtk4"

require_relative "app/models/campo_informe"
require_relative "app/models/tipo_informe"

require_relative "app/services/tipo_informe_service"

require_relative "app/controllers/nuevo_informe_controller"

require_relative "app/views/main_window_view"
require_relative "app/views/nuevo_informe_view"


class GeneradorInformes

  def initialize
    @app = Gtk::Application.new(
      "com.generadorinformes.app",
      :flags_none
    )

    @app.signal_connect("activate") do |application|
      mostrar_ventana_principal(application)
    end
  end


  def ejecutar
    @app.run
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


  def cargar_informe
    puts "Cargar informe"
  end

end


GeneradorInformes.new.ejecutar
