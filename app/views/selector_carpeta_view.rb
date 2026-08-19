require "gtk4"

class SelectorCarpetaView

  def initialize(
    application,
    carpeta_inicial:,
    on_seleccionar:,
    on_cancelar:
  )

    @application = application
    @carpeta_actual = carpeta_inicial
    @on_seleccionar = on_seleccionar
    @on_cancelar = on_cancelar

    crear_ventana
    cargar_carpeta
  end

  def mostrar
    @ventana.present
  end

  private

  # ============================================================
  # CREAR VENTANA
  # ============================================================

  def crear_ventana

    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Seleccionar carpeta"
    @ventana.set_default_size(750, 550)

    principal = Gtk::Box.new(
      :vertical,
      12
    )

    principal.margin_top = 20
    principal.margin_bottom = 20
    principal.margin_start = 25
    principal.margin_end = 25

    # -----------------------------
    # Título
    # -----------------------------

    titulo = Gtk::Label.new(
      "Seleccionar carpeta"
    )

    titulo.add_css_class("title-2")
    titulo.halign = :start

    principal.append(titulo)

    # -----------------------------
    # Ruta actual
    # -----------------------------

    @ruta_label = Gtk::Label.new

    @ruta_label.halign = :start
    @ruta_label.ellipsize = :middle
    @ruta_label.hexpand = true

    principal.append(@ruta_label)

    # -----------------------------
    # Lista
    # -----------------------------

    @lista = Gtk::ListBox.new

    @lista.selection_mode = :single

    @lista.signal_connect(
      "row-activated"
    ) do |_, fila|

      ruta = fila.data["ruta"]

      entrar_en_carpeta(ruta) if ruta

    end

    scroll = Gtk::ScrolledWindow.new

    scroll.vexpand = true
    scroll.hexpand = true
    scroll.child = @lista

    principal.append(scroll)

    # -----------------------------
    # Botones
    # -----------------------------

    botones = Gtk::Box.new(
      :horizontal,
      10
    )

    botones.halign = :end

    boton_atras = Gtk::Button.new(
      label: "← Atrás"
    )

    boton_cancelar = Gtk::Button.new(
      label: "Cancelar"
    )

    boton_seleccionar = Gtk::Button.new(
      label: "Seleccionar carpeta"
    )

    boton_seleccionar.add_css_class(
      "suggested-action"
    )

    boton_atras.signal_connect(
      "clicked"
    ) do
      ir_atras
    end

    boton_cancelar.signal_connect(
      "clicked"
    ) do

      @ventana.close

      @on_cancelar.call

    end

    boton_seleccionar.signal_connect(
      "clicked"
    ) do

      seleccionar

    end

    botones.append(boton_atras)
    botones.append(boton_cancelar)
    botones.append(boton_seleccionar)

    principal.append(botones)

    @ventana.child = principal
  end

  # ============================================================
  # CARGAR CARPETA
  # ============================================================

  def cargar_carpeta

    @ruta_label.text =
      "📁  #{@carpeta_actual}"

    @lista.remove_all

    begin

      carpetas = Dir.children(
        @carpeta_actual
      )
      .map do |nombre|

        File.join(
          @carpeta_actual,
          nombre
        )

      end
      .select do |ruta|

        File.directory?(ruta)

      end
      .sort_by do |ruta|

        File.basename(ruta).downcase

      end

      carpetas.each do |ruta|

        nombre = File.basename(ruta)

        fila = Gtk::ListBoxRow.new

        etiqueta = Gtk::Label.new(
          "📁  #{nombre}"
        )

        etiqueta.halign = :start

        etiqueta.margin_top = 10
        etiqueta.margin_bottom = 10
        etiqueta.margin_start = 15
        etiqueta.margin_end = 15

        fila.child = etiqueta

        fila.set_data(
          "ruta",
          ruta
        )

        @lista.append(fila)
      end

    rescue StandardError => e

      mostrar_error(
        "No se puede acceder a esta carpeta.\n\n#{e.message}"
      )

    end
  end

  # ============================================================
  # ENTRAR EN CARPETA
  # ============================================================

  def entrar_en_carpeta(ruta)

    return unless ruta

    return unless File.directory?(ruta)

    @carpeta_actual = ruta

    cargar_carpeta
  end

  # ============================================================
  # ATRÁS
  # ============================================================

  def ir_atras

    padre = File.dirname(
      @carpeta_actual
    )

    return if padre == @carpeta_actual

    @carpeta_actual = padre

    cargar_carpeta
  end

  # ============================================================
  # SELECCIONAR
  # ============================================================

  def seleccionar

    puts
    puts "========================================"
    puts "CARPETA SELECCIONADA"
    puts "========================================"
    puts @carpeta_actual
    puts "========================================"

    @ventana.close

    @on_seleccionar.call(
      @carpeta_actual
    )
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

    dialogo.signal_connect(
      "response"
    ) do

      dialogo.close

    end

    dialogo.present
  end

end

