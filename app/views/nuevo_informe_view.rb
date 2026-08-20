require "gtk4"

class NuevoInformeView
  def initialize(application, tipos, on_continuar:, on_volver:)
    @application = application
    @tipos = tipos
    @on_continuar = on_continuar
    @on_volver = on_volver

    @items = []
    @seleccion_actual = nil
    @cambiando_seleccion = false

    crear_ventana
  end

  def mostrar
    @ventana.present
  end

  private

  def crear_ventana
    @ventana = Gtk::ApplicationWindow.new(@application)

    @ventana.title = "Nuevo informe"
    @ventana.set_default_size(600, 400)
    @ventana.resizable = false

    contenedor = Gtk::Box.new(:vertical, 15)

    contenedor.margin_top = 40
    contenedor.margin_bottom = 40
    contenedor.margin_start = 50
    contenedor.margin_end = 50

    # ==========================================================
    # TÍTULO
    # ==========================================================

    titulo = Gtk::Label.new("NUEVO INFORME")
    titulo.add_css_class("title-1")

    descripcion = Gtk::Label.new(
      "Seleccione el tipo de informe"
    )

    descripcion.halign = :start

    contenedor.append(titulo)
    contenedor.append(descripcion)

    # ==========================================================
    # MODELO DEL SELECTOR
    # ==========================================================

    @modelo = Gtk::StringList.new([])

    # ==========================================================
    # SELECTOR
    # ==========================================================

    @selector = Gtk::DropDown.new(@modelo, nil)

    @selector.hexpand = true

    # Buscador integrado dentro del selector
    @selector.enable_search = true

    # ==========================================================
    # FACTORY DEL SELECTOR
    # ==========================================================

    factory = Gtk::SignalListItemFactory.new

    # ----------------------------------------------------------
    # CREAR ELEMENTO
    # ----------------------------------------------------------

    factory.signal_connect("setup") do |_factory, list_item|
      label = Gtk::Label.new

      label.halign = :start
      label.hexpand = true

      list_item.child = label
    end

    # ----------------------------------------------------------
    # CONFIGURAR ELEMENTO
    # ----------------------------------------------------------

    factory.signal_connect("bind") do |_factory, list_item|
      label = list_item.child
      posicion = list_item.position

      item = @items[posicion]

      next if item.nil?

      label.text = item[:nombre]

      # --------------------------------------------------------
      # CABECERAS EN NEGRITA
      # --------------------------------------------------------

      if item[:cabecera]
        label.add_css_class("heading")
      else
        label.remove_css_class("heading")
      end

      # --------------------------------------------------------
      # PLACEHOLDER
      # --------------------------------------------------------

      if item[:placeholder]
        label.add_css_class("dim-label")
      else
        label.remove_css_class("dim-label")
      end
    end

    @selector.factory = factory

    # ==========================================================
    # CARGAR TIPOS
    # ==========================================================

    cargar_tipos

    # ==========================================================
    # CAMBIO DE SELECCIÓN
    # ==========================================================

    @selector.signal_connect("notify::selected") do
      procesar_seleccion
    end

    contenedor.append(@selector)

    # ==========================================================
    # BOTONES
    # ==========================================================

    botones = Gtk::Box.new(:horizontal, 10)

    botones.margin_top = 15

    boton_volver = Gtk::Button.new(label: "Volver")
    boton_continuar = Gtk::Button.new(label: "Continuar")

    boton_volver.hexpand = true
    boton_continuar.hexpand = true

    # ==========================================================
    # BOTÓN VOLVER
    # ==========================================================

    boton_volver.signal_connect("clicked") do
      @ventana.close
      @on_volver.call
    end

    # ==========================================================
    # BOTÓN CONTINUAR
    # ==========================================================

    boton_continuar.signal_connect("clicked") do
      tipo = @seleccion_actual

      # No continuar si no hay informe seleccionado
      next if tipo.nil?

      @ventana.close
      @on_continuar.call(tipo)
    end

    botones.append(boton_volver)
    botones.append(boton_continuar)

    contenedor.append(botones)

    # ==========================================================
    # VENTANA
    # ==========================================================

    @ventana.child = contenedor
  end

  # ============================================================
  # CARGAR TIPOS AGRUPADOS POR ÁREA
  # ============================================================

  def cargar_tipos
    # ----------------------------------------------------------
    # PLACEHOLDER
    # ----------------------------------------------------------

    @items << {
      placeholder: true,
      cabecera: false,
      tipo: nil,
      nombre: "Seleccione un tipo de informe..."
    }

    @modelo.append(
      "Seleccione un tipo de informe..."
    )

    # ----------------------------------------------------------
    # AGRUPAR POR ÁREA
    # ----------------------------------------------------------

    agrupados = @tipos.group_by do |tipo|
      tipo.area || "otros"
    end

    agrupados.each do |area, tipos_area|

      # --------------------------------------------------------
      # CABECERA
      # --------------------------------------------------------

      texto_area = "── #{nombre_area(area)} ──"

      @items << {
        placeholder: false,
        cabecera: true,
        tipo: nil,
        area: area,
        nombre: texto_area
      }

      @modelo.append(texto_area)

      # --------------------------------------------------------
      # INFORMES
      # --------------------------------------------------------

      tipos_area.each do |tipo|

        @items << {
          placeholder: false,
          cabecera: false,
          tipo: tipo,
          area: area,
          nombre: tipo.nombre
        }

        @modelo.append(
          "   #{tipo.nombre}"
        )
      end
    end

    # ==========================================================
    # SELECCIÓN INICIAL
    # ==========================================================
    #
    # Gtk::DropDown selecciona automáticamente el primer
    # elemento. El primero es el placeholder, por lo que
    # no aparecerá Clínica Forense seleccionada.
    #

    @selector.selected = 0
  end

  # ============================================================
  # PROCESAR SELECCIÓN
  # ============================================================

  def procesar_seleccion
    return if @cambiando_seleccion

    indice = @selector.selected

    return if indice.nil?
    return if indice < 0
    return if indice >= @items.length

    item = @items[indice]

    return if item.nil?

    # ==========================================================
    # PLACEHOLDER
    # ==========================================================

    if item[:placeholder]
      return
    end

    # ==========================================================
    # CABECERA
    # ==========================================================

    if item[:cabecera]
      volver_a_seleccion_anterior
      return
    end

    # ==========================================================
    # INFORME VÁLIDO
    # ==========================================================

    @seleccion_actual = item[:tipo]
  end

  # ============================================================
  # VOLVER A LA SELECCIÓN ANTERIOR
  # ============================================================

  def volver_a_seleccion_anterior
    @cambiando_seleccion = true

    begin
      if @seleccion_actual
        indice = @items.index do |item|
          item[:tipo]&.id == @seleccion_actual.id
        end

        if indice
          @selector.selected = indice
        else
          @selector.selected = 0
        end
      else
        @selector.selected = 0
      end
    ensure
      @cambiando_seleccion = false
    end
  end

  # ============================================================
  # NOMBRE LEGIBLE DEL ÁREA
  # ============================================================

  def nombre_area(area)
    nombres = {
      "clinica_forense" => "Clínica Forense",
      "psiquiatria_forense" => "Psiquiatría Forense",
      "patologia_forense" => "Patología Forense",
      "laboratorio_forense" => "Laboratorio Forense",
      "transversal" => "Transversal",
      "otros" => "Otros"
    }

    nombres[area.to_s] || area.to_s
  end
end